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
        root = Path.cwd(),
        rules=[rules],
        builders=[builders],
        writer = BuildTool.Writers.TEST
    )
    target = buildtool.builder1(
        source = 'source_1',
        target = 'target_1',
    )
    assert target == 'target_1'
    writer = buildtool.run()
    assert list(writer.rules.keys()) == ['rule1']
    rule1 = writer.rules['rule1']
    assert rule1.name == 'rule1'
    assert rule1.command == '$a $in $out'
    assert rule1.depfile == None
    assert rule1.pool == None
    assert len(writer.builds) == 1
    build1 = writer.builds[0]
    assert build1.outputs == ['target_1']
    assert build1.rule == 'rule1'
    assert build1.inputs == ['source_1']
    assert build1.variables == {'a': 'a_val'}
    assert build1.implicit == None
    assert build1.implicit_outputs == []
    assert build1.pool == None
    assert list(writer.variables.keys()) == ['root']
    root_var = writer.variables['root']
    assert root_var.key == 'root'
    assert root_var.value == Path.cwd()
    assert len(writer.defaults) == 0

