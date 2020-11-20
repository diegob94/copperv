import os

from waflib import TaskGen
from waflib.Tools import c as c_tool

APPNAME = 'copperv'
VERSION = '0.1'

top = '.'
out = 'work'
riscv = f'{os.environ["RISCV"]}/bin/riscv64-unknown-elf-'

def options(opt):
    opt.load('gcc')

@TaskGen.feature('asmstlib')
def asmstlib(*args, **kwargs):
    print('asmtlib',args,kwargs)

@TaskGen.extension('.S')
def s_hook(*args, **kwargs):
    c_tool.c_hook(*args, **kwargs)

def configure(conf):
    conf.env.CC = f'{riscv}gcc'
    conf.env.AR = f'{riscv}ar'
    conf.env.append_value('CFLAGS', '-march=rv32i')
    conf.env.append_value('CFLAGS', '-mabi=ilp32')
    top_dir = conf.path.get_src()
    conf.env.SDK = f'{top_dir}/sdk'
    linker_script = f'{top_dir}/sdk/linker.ld'
    conf.env.append_value('LINKFLAGS', [f'-Wl,-T,{linker_script},--strip-debug,-Bstatic', '-nostdlib', '-ffreestanding'])
    conf.load('gcc')

def build(bld):
#    bld.recurse(bld.env.SDK)
    bld.recurse(f'{bld.top_dir}/sim/tests/common')
    bld.recurse(f'{bld.top_dir}/sim/tests/simple')


