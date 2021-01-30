import dataclasses

from scripts.build_tools import Rule, Builder, Build

def c_rules(build):
    build.rules['object'] = Rule(
        command = '$cc $cflags -MD -MF $out.d -c $in -o $out',
        depfile = '$out.d',
        variables = ['cc','cflags'],
    )
    build.rules['preprocess'] = Rule(
        command = '$cc $cflags -c $in -o $out',
        variables = ['cc','cflags'],
    )
    build.rules['link'] = Rule(
        command = '$cc $linkflags $in -o $out',
        variables = ['cc','linkflags'],
    )
    build.rules['verilog_hex'] = Rule(
        command = '$objcopy -O verilog $in $out',
        variables = ['objcopy'],
    )
    build.rules['dissassemble'] = Rule(
        command = '$monitor_utils dissassemble $in -o $out -objdump $objdump',
        variables = ['monitor_utils','objdump'],
    )

def test_builders(build):
    build.builders['test_object'] = Builder(
        rule = 'object',
        cc = 'riscv64-unknown-elf-gcc',
        cflags = lambda inc_dir: ['-march=rv32i','-mabi=ilp32'] + [f' -I{i}' for i in inc_dir],
        kwargs = ['inc_dir'],
    )
    build.builders['test_preprocess'] = Builder(
        rule = 'preprocess',
        cc = 'riscv64-unknown-elf-gcc',
        cflags = lambda **kwargs: (build.test_object.variables['cflags'](**kwargs) + ['-E']),
        kwargs = ['inc_dir'],
    )
    linker_script = build.root/'sim/tests/common/linker.ld'
    build.builders['test_link'] = Builder(
        rule = 'link',
        cc='riscv64-unknown-elf-gcc',
        linkflags = f'-Wl,-T,{linker_script},--strip-debug,-Bstatic -nostdlib -ffreestanding',
    )
    build.builders['test_verilog_hex'] = Builder(
        rule = 'verilog_hex',
        objcopy='riscv64-unknown-elf-objcopy',
    )
    build.builders['test_dissassemble'] = Builder(
        rule = 'dissassemble',
        monitor_utils = build.root/'scripts/monitor_utils.py',
        objdump='riscv64-unknown-elf-objdump',
    )

def sim_rules(build):
    build.rules['vvp'] = Rule(
        command = 'cd $wd && vvp $vvpflags $in $plusargs 2>&1 | tee ${logs_dir}/run_sim_${test_name}.log',
        variables = ['wd','vvpflags','plusargs','logs_dir','test_name'],
    )

def sim_builders(build):
    build.builders['sim_run'] = Builder(
        rule = 'vvp',
        wd = lambda **kwargs: kwargs['wd'],
        vvpflags = '-M. -mcopperv_tools',
        plusargs = lambda **kwargs: f'+HEX_FILE={kwargs["hex_file"]} +DISS_FILE={kwargs["diss_file"]}',
        logs_dir = lambda **kwargs: kwargs['logs_dir'],
        test_name = lambda **kwargs: kwargs['test_name'],
        kwargs = ['wd','hex_file','diss_file','logs_dir','test_name'],
        implicit = [
            lambda **kwargs: kwargs['hex_file'], # -> list
            lambda **kwargs: kwargs['diss_file'],
        ],
    )

build = Build(
    rules=[c_rules,sim_rules],
    builders=[test_builders,sim_builders]
)

test_root = build.root/'sim/tests'

@dataclasses.dataclass
class Test:
    name: str
    source: list
    inc_dir: list = dataclasses.field(default_factory=list)

tests = dict(
    simple = Test(
        name = 'simple',
        source = [test_root/'common/asm/crt0.S',test_root/'simple/test_0.S'],
        inc_dir = [test_root/'common'],
    ),
)
