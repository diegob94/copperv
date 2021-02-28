import sys
from pathlib import Path
sys.path.append(str(Path(__file__).resolve().parent.parent))
from scripts.build_tools import Rule, Builder, BuildTool
import pytest
from pytest import fail, fixture, CaptureFixture
import re

def split(x):
    return re.split(r'\s+',x)

@fixture
def fake_project(tmp_path: Path):
    test_files = ['source_1']
    files = {}
    for i,name in enumerate(test_files):
        f = tmp_path/name
        f.write_text(f'test file #{i}')
        files[name] = f
    return dict(root=tmp_path,files=files)

def checkcmd(capfd,cmd):
    __tracebackhide__ = True
    passed = False
    backend_out = capfd.readouterr().out
    for line in backend_out.splitlines():
        if cmd[0] in line:
            if split(line)[1:] == cmd:
                passed = True
                break
    if not passed:
        fail(f'Command "{" ".join(cmd)}" not found in backend output\nBackend output:\n{backend_out}')

def test_simple_build(fake_project: Path, capfd):
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
        root = fake_project['root'],
        rules=[rules],
        builders=[builders],
    )
    target = buildtool.builder1(
        source = 'source_1',
        target = 'target_1',
    )
    assert target == 'target_1'
    writer = buildtool.run(ninja_opts='-n')
    checkcmd(capfd,['a_val1',str(fake_project["files"]["source_1"]),'target_1'])
