import sys
from pathlib import Path
sys.path.append(str(Path(__file__).resolve().parent.parent))
from scripts.build_tools import Rule, Builder, BuildTool

def test_simple_build():
    def rules(buildtool):
        buildtool.rules['rule1'] = Rule(
            command = '$a $in $out',
            variables = ['a'],
        )
    def builders(buildtool):
        buildtool.builders['builder1'] = Builder(
            rule = 'rule1',
            a = 'a_val',
        )
    buildtool = BuildTool(
        rules=[rules],
        builders=[builders],
        writer = BuildTool.Writers.TEST
    )
    target = buildtool.builder1(
        source = 'source_1',
        target = 'target_1',
    )
    assert target == 'target_1'
    print(f"running {Path.cwd()}")
    buildtool.run()
    assert False

