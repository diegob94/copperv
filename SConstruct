import os

env = Environment(
    tools=['default', 'copperv_tools'],
    toolpath=['scripts'],
    ENV = {'PATH' : os.environ['PATH']},
    CPPPATH='#sim/tests/common',
    OBJCOPY='riscv64-unknown-elf-objcopy',
    OBJDUMP='riscv64-unknown-elf-objdump',
    CC='riscv64-unknown-elf-gcc',
    CFLAGS='-march=rv32i -mabi=ilp32',
    LINKER_SCRIPT=File('#/sim/tests/common/linker.ld'),
    LINKFLAGS = '-Wl,-T,${LINKER_SCRIPT},--strip-debug,-Bstatic -nostdlib -ffreestanding',
)
env['ASFLAGS'] = env['CFLAGS']

test_paths = [
    'sim/tests/common',
    'sim/tests/simple',
    'sim'
]

for test_path in test_paths:
    SConscript(f'#{test_path}/SConscript',
        variant_dir=f'#work/{test_path}',
        duplicate = False,
        exports = 'env'
    )

