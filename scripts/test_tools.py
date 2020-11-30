from SCons.Script import *

try:
    from scripts.monitor_utils import generate_dissassembly_file
except ImportError:
    def exists(env): return False
else:
    def exists(env): return True

def generate(env):
    hexfile = Builder(
        action = '$OBJCOPY -O verilog $SOURCE $TARGET',
        suffix = '.hex_file',
        src_suffix = '.elf',
    )
    dissassembly = Builder(
        action = dissassembly_file_builder,
        suffix = '.D',
        src_suffix = '.elf',
    )
    env.Append(BUILDERS = {
        'HexfileBuilder' : hexfile,
        'Dissassembly'   : dissassembly,
    })
    env.AddMethod(test, "Test")

def dissassembly_file_builder(target, source, env):
    """ SCons Builder wrapper """
    generate_dissassembly_file(str(target[0]), str(source[0]), env['OBJDUMP'])
    return None

def test(env, target, source, **kwargs):
    program = env.Program(f'{target}.elf', source, **kwargs)
    hf = env.HexfileBuilder(program)
    diss = env.Dissassembly(program)
    return hf+diss


