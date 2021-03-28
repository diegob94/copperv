import dataclasses
from pathlib import Path

from scripts.build_tools import Rule, Builder, BuildTool

def c_rules(buildtool):
    buildtool.rules['object'] = Rule(
        command = '$cc $_cflags -MD -MF $out.d -c $in -o $out',
        depfile = '$out.d',
    )
    buildtool.rules['preprocess'] = Rule(
        command = '$cc $_cflags -c $in -o $out',
    )
    buildtool.rules['link'] = Rule(
        command = '$cc $_linkflags $in -o $out',
    )
    buildtool.rules['verilog_hex'] = Rule(
        command = '$dev_utils hex -objcopy $objcopy -readelf $readelf -elf_file $in -o $out',
    )
    buildtool.rules['dissassemble'] = Rule(
        command = '$dev_utils dissassemble $in -o $out -objdump $objdump',
    )

def test_builders(buildtool):
    toolchain = 'riscv64-unknown-elf-'
    cflags = ['-march=rv32i','-mabi=ilp32']
    cflags.append('-g')
    buildtool.builders['test_object'] = Builder(
        rule = 'object',
        cc = toolchain + 'gcc',
        _cflags = '$cflags',
    )
    buildtool.builders['test_preprocess'] = Builder(
        rule = 'preprocess',
        cc = toolchain + 'gcc',
        _cflags = f"{buildtool.test_object.variables['_cflags']} -E",
    )
    linker_script = buildtool.root/'sim/tests/common/linker.ld'
    ldflags = ['-Wl','-T',str(linker_script),'-Bstatic']
    #ldflags.append('--strip-debug')
    buildtool.builders['test_link'] = Builder(
        rule = 'link',
        cc = toolchain + 'gcc',
        linkflags = cflags + [','.join(ldflags),'-nostartfiles','-ffreestanding'],
    )
    dev_utils = buildtool.root/'scripts/dev_utils.py'
    buildtool.builders['test_verilog_hex'] = Builder(
        rule = 'verilog_hex',
        objcopy = toolchain + 'objcopy',
        readelf = toolchain + 'readelf',
        dev_utils = dev_utils,
    )
    buildtool.builders['test_dissassemble'] = Builder(
        rule = 'dissassemble',
        dev_utils = dev_utils,
        objdump = toolchain + 'objdump',
    )

def sim_rules(buildtool):
    buildtool.rules['vvp'] = Rule(
        command = 'cd $cwd && vvp $vvpflags $in $plusargs',
        pool = 'console',
    )
    buildtool.rules['iverilog'] = Rule(
        command = "cd $cwd && iverilog $_iverilogflags $in -o $out",
    )
    buildtool.rules['vpi'] = Rule(
        command = 'cd $cwd; iverilog-vpi $in',
    )
    buildtool.rules['show_stdout'] = Rule(
        command = 'cat $in | sed "s/^/sim_stdout> /"',
        no_output = True,
    )
    buildtool.rules['gtkwave'] = Rule(
        command = "gtkwave --rcvar 'splash_disable on' -A -a $cwd/sim.gtkw $in",
        pool = 'console',
    )

def sim_builders(buildtool):
    buildtool.builders['sim_run'] = Builder(
        rule = 'vvp',
        vvpflags = '-M. -mcopperv_tools',
        plusargs = '+HEX_FILE=$hex_file +DISS_FILE=$diss_file',
        implicit = [
            '$hex_file',
            '$diss_file',
        ],
        check_log = 'grep -q "TEST PASSED" $log',
    )
    buildtool.builders['sim_compile'] = Builder(
        rule = 'iverilog',
        _iverilogflags = '-Wall -Wno-timescale -g2012 $iverilogflags',
        implicit = [
            '$header_files',
            '$tools_vpi',
        ],
        check_log = '! grep -q error $log',
    )
    buildtool.builders['vpi'] = Builder(
        rule = 'vpi',
    )
    buildtool.builders['show_stdout'] = Builder(
        rule = 'show_stdout',
    )
    buildtool.builders['gtkwave'] = Builder(
        rule = 'gtkwave',
    )

buildtool = BuildTool(
    root = Path(__file__).parent.parent.resolve(),
    rules=[c_rules,sim_rules],
    builders=[test_builders,sim_builders]
)

test_root = buildtool.root/'sim/tests'

@dataclasses.dataclass
class Test:
    name: str
    source: list
    inc_dir: list = dataclasses.field(default_factory=list)
    show_stdout: bool = False

tests = dict(
    simple = Test(
        name = 'simple',
        source = [test_root/'common/asm/crt0.S',test_root/'simple/test_0.S'],
        inc_dir = [test_root/'common'],
    ),
    rv32ui = Test(
        name = 'rv32ui',
        source = [test_root/'common/asm/crt0.S']
            + list((test_root/'isa/rv32ui').glob('*.S')),
        inc_dir = [
            test_root/'common',
            test_root/'isa'
        ],
    ),
    hello_world = Test(
        name = 'hello_world',
        source = [test_root/'common/c/crt0.S']
            + list((test_root/'hello_world').glob('*.c')),
        inc_dir = [
            test_root/'common',
            test_root/'common/c',
        ],
        show_stdout = True,
    ),
    dhrystone = Test(
        name = 'dhrystone',
        source = [test_root/'common/c/crt0.S']
            + list((test_root/'dhrystone').glob('*.c')),
        inc_dir = [
            test_root/'common',
            test_root/'common/c',
            test_root/'dhrystone',
        ],
        show_stdout = True,
    ),
)
