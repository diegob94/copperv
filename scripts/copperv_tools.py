import dataclasses

from scripts.build_tools import Rule, Builder, Build

def c_rules(build):
    build.rules['object'] = Rule(
        command = '$cc $cflags -MD -MF $out.d -c $in -o $out',
        depfile = '$out.d',
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
        cflags = lambda **kwargs: '-march=rv32i -mabi=ilp32' + ''.join([f' -I{i}' for i in kwargs['inc_dir']]),
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

build = Build(rules=c_rules,builders=test_builders)

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
