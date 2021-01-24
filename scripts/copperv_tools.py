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

build = Build(rules=c_rules,builders=test_builders)

test_root = build.root/'sim/tests'

@dataclasses.dataclass
class Test:
    name: str
    target: str
    source: list
    inc_dir: list = dataclasses.field(default_factory=list)

tests = dict(
    simple = Test(
        name = 'simple',
        target = 'simple.hex',
        source = [test_root/'common/asm/crt0.S',test_root/'simple/test_0.S'],
        inc_dir = [test_root/'common'],
    ),
)
