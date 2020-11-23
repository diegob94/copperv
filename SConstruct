import os

env = Environment(
    ENV = {'PATH' : os.environ['PATH']},
    CPPPATH='#sim/tests/common',
    OBJCOPY='riscv64-unknown-elf-objcopy',
    CC='riscv64-unknown-elf-gcc',
    CFLAGS='-march=rv32i -mabi=ilp32',
    LINKER_SCRIPT=File('#/sim/tests/common/linker.ld'),
    LINKFLAGS = '-Wl,-T,${LINKER_SCRIPT},--strip-debug,-Bstatic -nostdlib -ffreestanding',
)
env['ASFLAGS'] = env['CFLAGS']

test_paths = [
    'sim/tests/common',
    'sim/tests/simple',
]

hexfile = Builder(
    action = '$OBJCOPY -O verilog $SOURCE $TARGET',
    suffix = '.hex_file',
    src_suffix = '.elf',
)
env['BUILDERS'].update({'HexfileBuilder' : hexfile})

def hexfile(env, target, source, **kwargs):
    program = env.Program(f'{target}.elf', source, **kwargs)
    hf = env.HexfileBuilder(program)
    return hf
env.AddMethod(hexfile, "Hexfile")

for test_path in test_paths:
    SConscript(f'#{test_path}/SConscript', variant_dir=f'#work/{test_path}', duplicate = False, exports = 'env')

