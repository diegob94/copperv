import os

env = Environment(
    ENV = {'PATH' : os.environ['PATH']},
    BUILD_DIR = '#work',
    CPPPATH='#sim/tests/common',
    CC='riscv64-unknown-elf-gcc',
    CFLAGS='-march=rv32i -mabi=ilp32',
    LINKER_SCRIPT='./sim/tests/common/linker.ld',
    LINKFLAGS = '-Wl,-T,${LINKER_SCRIPT},--strip-debug,-Bstatic -nostdlib -ffreestanding',
)
env['ASFLAGS'] = env['CFLAGS']

scripts = [
    'sim/tests/common',
    'sim/tests/simple',
]

for script in scripts:
    SConscript(f'#{script}/SConscript', variant_dir=f'#work/{script}', duplicate = False, exports = 'env')

