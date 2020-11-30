import os
import subprocess as sp

def run(cmd):
    #print(cmd)
    r = sp.run(cmd,shell=True,capture_output=True,check=True,encoding='utf-8').stdout.strip()
    #print(r)
    return r

env = Environment(
    ENV = {'PATH' : os.environ['PATH']},
    toolpath=['scripts'],
)

sim_env = env.Clone(
    tools=['default', 'sim_tools'],
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
        'HEX_FILE':'$HEX_FILE',
        'DISS_FILE':'$DISS_FILE',
    },
)

#ICARUSFLAGS += -I$(STD_OVL) -y$(STD_OVL)
#ICARUSFLAGS += -DENABLE_CHECKER
#ICARUSFLAGS += -pfileline=1

test_env = env.Clone(
    tools=['default', 'test_tools'],
    CPPPATH='#sim/tests/common',
    OBJCOPY='riscv64-unknown-elf-objcopy',
    OBJDUMP='riscv64-unknown-elf-objdump',
    CC='riscv64-unknown-elf-gcc',
    CFLAGS='-march=rv32i -mabi=ilp32',
    LINKER_SCRIPT=File('#/sim/tests/common/linker.ld'),
    LINKFLAGS = '-Wl,-T,${LINKER_SCRIPT},--strip-debug,-Bstatic -nostdlib -ffreestanding',
    ASFLAGS = '$CFLAGS'
)

duplicate = False

SConscript('#sim/tests/common/SConscript',
    variant_dir='#work/sim/tests/common',
    duplicate = duplicate,
    exports = {'env':test_env},
)

test_outputs = SConscript('#sim/tests/simple/SConscript',
    variant_dir='#work/sim/tests/simple',
    duplicate = duplicate,
    exports = {'env':test_env},
)

ext_map = {'.hex_file':'HEX_FILE','.D':'DISS_FILE'}
test_outputs = {ext_map[f.suffix]:f for f in test_outputs}
sim_env.Append(**test_outputs)

SConscript('#sim/SConscript',
    variant_dir='#work/sim',
    duplicate = duplicate,
    exports = {'env':sim_env},
)

