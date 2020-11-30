from SCons.Script import Builder, Scanner, FindPathDirs, FindFile
from pathlib import Path
import re

try:
    from scripts.monitor_utils import generate_monitor_printer
except ImportError:
    def exists(env): return False
else:
    def exists(env): return True

def generate(env):
    monitor_printer = Builder(
        action = monitor_printer_builder,
        suffix = '.v',
        src_suffix = '.v',
    )
    vscan = Scanner(
        function = verilog_scan,
        skeys = ['.v'],
        path_function = FindPathDirs('VPPPATH')
    )
    iverilog = Builder(
        action = 'iverilog $IVERILOGFLAGS $_IVERILOGINCDIRS $SOURCES -o $TARGET',
        suffix = '.vvp',
        src_suffix = '.v',
        source_scanner = vscan,
    )
    env.Append(_IVERILOGINCDIRS = ' '.join([f'-I{env.Dir(p)}' for p in env['VPPPATH']]))
    vvpscan = Scanner(
        function = vvp_scan,
        path_function = FindPathDirs('VPIPATH')
    )
    vvp = Builder(
        action = 'vvp $VVPFLAGS $_VPIS $SOURCE $_PLUSARGS',
        suffix = '.vcd',
        src_suffix = '.vvp',
        target_scanner = vvpscan,
    )
    env.Append(BUILDERS = {
        'MonitorPrinter' : monitor_printer,
        'IVerilog' : iverilog,
        'VVP' : vvp,
    })

def monitor_printer_builder(target, source, env):
    """ SCons Builder wrapper """
    generate_monitor_printer(str(target[0]), str(source[0]))
    return None

include_re = re.compile(r'`include\s+"(\S+)"')
def verilog_scan(node, env, path, arg = None):
    contents = node.get_text_contents()
    includes = include_re.findall(contents)
    files = [FindFile(i,path) for i in includes]
    return files

def vvp_scan(node, env, path, arg = None):
    vpis = env['VPIS']
    if isinstance(vpis,str):
        vpis = [vpis]
    flags = []
    files = []
    for vpi in vpis:
        vpi = str(Path(vpi).with_suffix('.vpi'))
        file = FindFile(vpi,path)
        if file is not None:
            file_p = Path(file.abspath)
            flags.append(f'-M{env.Dir(file_p.parent).path}')
            flags.append(f'-m{file_p.stem}')
            files.append(file)
    env.AppendUnique(_VPIS = flags)
    plusargs = env['PLUSARGS']
    if isinstance(plusargs,str):
        plusargs = {plusargs:None}
    env.Append(_PLUSARGS = [f'+{k}' if v is None else f'+{k}={v}' for k,v in plusargs.items()])
    return files

