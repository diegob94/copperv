#!/usr/bin/env python
import sys
import io
from pathlib import Path
#import scripts.sim_tools as sim
#import scripts.test_tools as test
import os
import subprocess as sp
import ninja
from string import Template
import dataclasses

class MyTemplate(Template):
    def __init__(self,*args, **kwargs):
        super().__init__(*args, **kwargs)
        self.var_names = self.get_var_names()
    def get_var_names(self):
        var_names= []
        for i in self.pattern.finditer(self.template):
            i = i.groupdict()
            if i['named'] is not None:
                var_names.append(i['named'])
            elif i['braced'] is not None:
                var_names.append(i['braced'])
        return var_names

@dataclasses.dataclass
class Test:
    target: list
    source: list
    inc_dir: list = dataclasses.field(default_factory=list)
    def subst(self,env):
        self.target = [env.subst_var('target',t) for t in self.target]
        self.source = [env.subst_var('source',t) for t in self.source]
        self.inc_dir = [env.subst_var('inc_dir',t) for t in self.inc_dir]

def get_root():
    return str(Path(__file__).parent.absolute())

def run(cmd):
    #print(cmd)
    r = sp.run(cmd,shell=True,capture_output=True,check=True,encoding='utf-8').stdout.strip()
    #print(r)
    return r

config = dict(
    root = get_root(),
    build_dir = '$root/work',
)

sim_env = dict(
    CFLAGS = run('iverilog-vpi --cflags'),
    LINKFLAGS = run('iverilog-vpi --ldflags'),
    _LIBFLAGS = run('iverilog-vpi --ldlibs'),
    VPPPATH = ['#rtl/include', '#sim/include', "#work/sim/include"],
    IVERILOGFLAGS = [
        '-Wall',
        '-Wno-timescale',
        '-g2012',
    ],
    VPIPATH = '#work/sim',
    VPIS='copperv_tools',
    PLUSARGS = {
        'HEX_FILE':'{HEX_FILE}',
        'DISS_FILE':'{DISS_FILE}',
    },
)

#ICARUSFLAGS += -I$(STD_OVL) -y$(STD_OVL)
#ICARUSFLAGS += -DENABLE_CHECKER
#ICARUSFLAGS += -pfileline=1

test_env_vars = dict(
    OBJCOPY='riscv64-unknown-elf-objcopy',
    OBJDUMP='riscv64-unknown-elf-objdump',
    cc='riscv64-unknown-elf-gcc',
    cflags='-march=rv32i -mabi=ilp32',
    LINKER_SCRIPT='$root/sim/tests/common/linker.ld',
    linkflags = '-Wl,-T,$LINKER_SCRIPT,--strip-debug,-Bstatic -nostdlib -ffreestanding',
    tests = '$root/sim/tests',
)

test = Test(
    target = ['$tests/simple/simple.elf'],
    source = ['$tests/common/asm/crt0.S','$tests/simple/test_0.S'],
    inc_dir = ['$tests/common'],
)

class Environment:
    def __init__(self, _builders={},**kwargs):
        self.vars = dict(kwargs)
        self.builders = dict(_builders)
        self.subst()
        Path(self['build_dir']).mkdir(exist_ok='True')
        self.writer = NinjaWriter()
    def __setitem__(self,key,value):
        self.vars[key] = value
    def __contains__(self, key):
        return key in self.vars
    def __getitem__(self,key):
        return self.vars[key]
    def items(self):
        return self.vars.items()
    def keys(self):
        return self.var.keys()
    def translate_path(self, path):
        return Path(self['build_dir'])/Path(path).relative_to(self['root'])
    def _subst_var(self, name, template):
        try:
            s = MyTemplate(template).substitute(**self.vars)
        except KeyError as e:
            raise KeyError(f'Variable "{e.args[0]}" not found while expanding "{name} = {template}"') from e
        if s == template or not '$' in s:
            return s
        return self.subst_var(name, s)
    def subst_var(self, name, template):
        if isinstance(template, str):
            template = [template]
        r = [self._subst_var(name, t) for t in template]
        if len(r) == 1:
            return r[0]
        return r
    def subst(self):
        self.vars = {k:self.subst_var(k, v) for k,v in self.items()}
    def copy(self, **kwargs):
        builders = dict(_builders = self.builders) if hasattr(self, 'builders') else {}
        new_env = Environment(**builders,**self.vars,**kwargs)
        for b in new_env.builders.values():
            b.set_env(new_env)
        return new_env
    def addBuilder(self, **kwargs):
        for key, value in kwargs.items():
            self.builders[key] = value
            self.builders[key].write_rule(key)
    def __getattr__(self, key):
        if key != 'builders' and key in self.builders:
            return self.builders[key]
        return self.__getattribute__(key)
    def __repr__(self):
        kwargs = dict(_builder=self.builders,**self.vars)
        args = [f'{k}={repr(v)}' for k,v in kwargs.items()]
        temp = ",".join(args)
        return f'Environment({temp})'
    def write(self):
        ninja_path = Path(self['build_dir'])/'build.ninja'
        self.writer.write(ninja_path)

class SingletonMeta(type):
    _instances = {}
    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            instance = super().__call__(*args, **kwargs)
            cls._instances[cls] = instance
        return cls._instances[cls]

class NinjaWriter(metaclass=SingletonMeta):
    def __init__(self):
        self.fd = io.StringIO()
        self.writer = ninja.Writer(self.fd)
        self.ninja_vars = ['in','out']
    def close(self):
        self.fd.close()
    def __getattr__(self, key):
        if key != 'writer':
            return getattr(self.writer,key)
        return self.__getattribute__(key)
    def filter_ninja_vars(self, var_list):
        return [i for i in var_list if not i in self.ninja_vars]
    def write(self,ninja_path):
        ninja_path.write_text(self.fd.getvalue())

class Builder:
    def __init__(self, command, depfile = None, get_env = None):
        self.command = command
        self.depfile = depfile
        self.writer = NinjaWriter()
        command_vars = MyTemplate(self.command).var_names
        self.env_vars = self.writer.filter_ninja_vars(command_vars)
        self.env = None
        self.name = None
        self.get_env = get_env
    def __repr__(self):
        kwargs = self.get_kwargs()
        args = [f'{k}={repr(v)}' for k,v in kwargs.items()]
        temp = ",".join(args)
        return f'Builder({temp})'
    def get_kwargs(self):
        kwargs = dict(command = self.command)
        if self.depfile is not None:
            kwargs['depfile'] = self.depfile
        return kwargs
    def set_env(self, env):
        self.env = env
    def write_rule(self, name):
        self.name = name
        rule_kwargs = self.get_kwargs()
        self.writer.rule(self.name, **rule_kwargs)
    def __call__(self, target, source):
        env = self.env
        if callable(self.get_env):
            env = self.get_env(self.env.copy())
        for k in self.env_vars:
            self.writer.variable(k,env[k])
        if isinstance(source, str):
            source = [source]
        source = [Path(src) for src in source]
        if callable(target):
            target = [target(src) for src in source]
        translated_target = [env.translate_path(tgt) for tgt in target]
        for src,tgt in zip(source,translated_target):
            src = str(src)
            tgt = str(tgt)
            self.writer.build(tgt,self.name,src)
        return translated_target

env = Environment(**config)
def object_env(env):
    if 'inc_dir' in env:
        inc_dir = env['inc_dir']
        if isinstance(inc_dir,str):
            inc_dir = [inc_dir]
        env['cflags'] += ''.join([f' -I{i}' for i in inc_dir])
    return env
env.addBuilder(
    object = Builder(
        command = '$cc $cflags -MD -MF $out.d -c $in -o $out',
        depfile = '$out.d',
        get_env = object_env,
    ),
    link = Builder(
        command = '$cc $linkflags $in -o $out',
    ),
)
test_env = env.copy(**test_env_vars)

test.subst(test_env)
test_env['inc_dir'] = test.inc_dir

test_objs = test_env.object(
    target = lambda _in: _in.with_suffix('.o'),
    source = test.source
)
test_env.link(
    target = test.target,
    source = test_objs
)

test_env.write()


#
#class TestEnvironment(Environment):
#
#def HexFileBuilder(env, target, source):
#    suffix = '.hex_file'
#    src_suffix = '.elf'
#    return '$OBJCOPY -O verilog $SOURCE $TARGET'
#
#dissassembly = Builder(
#    action = dissassembly_file_builder,
#    suffix = '.D',
#    src_suffix = '.elf',
#)
#
#def dissassembly_file_builder(env, target, source):
#    generate_dissassembly_file(target[0], source[0], env['OBJDUMP'])
#    return target
#
#def test(env, target, source):
#    program = env.Link(f'{target}.elf', source)
#    hf = env.HexfileBuilder(program)
#    diss = env.Dissassembly(program)
#    return hf+diss
#
#

#sys.exit()
#
#env['CRT0'] = env.Object('asm/crt0.S')
#ext_map = {'.hex_file':'HEX_FILE','.D':'DISS_FILE'}
#
#
#test_outputs = env.Test('simple',['test_0.S']+env['CRT0'])
#
#test_outputs = {ext_map[f.suffix]:f for f in test_outputs}
#
#env.MonitorPrinter('include/monitor_utils_h.v','#rtl/include/copperv_h.v')
#env.Program('copperv_tools.vpi','copperv_tools.c')
#
#sim_src = Glob('*.v')+Glob('*.sv')
#sim_src = [f for f in sim_src if f.name != 'checker_cpu.v']
#rtl_src = Glob('#rtl/*.v')
#
#vvp = env.IVerilog('sim.vvp',sim_src + rtl_src)
#
#vcd_file = 'sim.vcd'
#env.Append(PLUSARGS = {'VCD_FILE':vcd_file})
#vcd = env.VVP(vcd_file,vvp)
#
#env.Depends(vcd, env['HEX_FILE'])
#env.Depends(vcd, env['DISS_FILE'])
#
##(base) ➜  copperv git:(master) ✗ cat ./sim/SConscript
##Import('env')
##
##env.MonitorPrinter('include/monitor_utils_h.v','#rtl/include/copperv_h.v')
##env.Program('copperv_tools.vpi','copperv_tools.c')
##
##sim_src = Glob('*.v')+Glob('*.sv')
#sim_src = [f for f in sim_src if f.name != 'checker_cpu.v']
#rtl_src = Glob('#rtl/*.v')
#
#vvp = env.IVerilog('sim.vvp',sim_src + rtl_src)
#
#vcd_file = 'sim.vcd'
#env.Append(PLUSARGS = {'VCD_FILE':vcd_file})
#vcd = env.VVP(vcd_file,vvp)
#
#env.Depends(vcd, env['HEX_FILE'])
#env.Depends(vcd, env['DISS_FILE'])

#(base) ➜  copperv git:(master) ✗ cat ./sim/tests/common/SConscript
#Import('env')
#
#
#
#ase) ➜  copperv git:(master) ✗ cat ./sim/tests/simple/SConscript
#Import('env')
#
#
#Return('test_outputs')
#


#from SCons.Script import Builder, Scanner, FindPathDirs, FindFile
#from pathlib import Path
#import re
#
#try:
#    from scripts.monitor_utils import generate_monitor_printer
#except ImportError:
#    def exists(env): return False
#else:
#    def exists(env): return True
#
#def generate(env):
#    monitor_printer = Builder(
#        action = monitor_printer_builder,
#        suffix = '.v',
#        src_suffix = '.v',
#    )
#    vscan = Scanner(
#        function = verilog_scan,
#        skeys = ['.v'],
#        path_function = FindPathDirs('VPPPATH')
#    )
#    iverilog = Builder(
#        action = 'iverilog $IVERILOGFLAGS $_IVERILOGINCDIRS $SOURCES -o $TARGET',
#        suffix = '.vvp',
#        src_suffix = '.v',
#        source_scanner = vscan,
#    )
#    env.Append(_IVERILOGINCDIRS = ' '.join([f'-I{env.Dir(p)}' for p in env['VPPPATH']]))
#    vvpscan = Scanner(
#        function = vvp_scan,
#        path_function = FindPathDirs('VPIPATH')
#    )
#    vvp = Builder(
#        action = 'vvp $VVPFLAGS $_VPIS $SOURCE $_PLUSARGS',
#        suffix = '.vcd',
#        src_suffix = '.vvp',
#        target_scanner = vvpscan,
#    )
#    env.Append(BUILDERS = {
#        'MonitorPrinter' : monitor_printer,
#        'IVerilog' : iverilog,
#        'VVP' : vvp,
#    })
#
#def monitor_printer_builder(target, source, env):
#    """ SCons Builder wrapper """
#    generate_monitor_printer(str(target[0]), str(source[0]))
#    return None
#
#include_re = re.compile(r'`include\s+"(\S+)"')
#def verilog_scan(node, env, path, arg = None):
#    contents = node.get_text_contents()
#    includes = include_re.findall(contents)
#    files = [FindFile(i,path) for i in includes]
#    return files
#
#def vvp_scan(node, env, path, arg = None):
#    vpis = env['VPIS']
#    if isinstance(vpis,str):
#        vpis = [vpis]
#    flags = []
#    files = []
#    for vpi in vpis:
#        vpi = str(Path(vpi).with_suffix('.vpi'))
#        file = FindFile(vpi,path)
#        if file is not None:
#            file_p = Path(file.abspath)
#            flags.append(f'-M{env.Dir(file_p.parent).path}')
#            flags.append(f'-m{file_p.stem}')
#            files.append(file)
#    env.AppendUnique(_VPIS = flags)
#    plusargs = env['PLUSARGS']
#    if isinstance(plusargs,str):
#        plusargs = {plusargs:None}
#    env.Append(_PLUSARGS = [f'+{k}' if v is None else f'+{k}={v}' for k,v in plusargs.items()])
#    return files
#
