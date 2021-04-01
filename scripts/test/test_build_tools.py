import sys
from pathlib import Path
sys.path.append(str(Path(__file__).resolve().parent.parent.parent))
from scripts.build_tools import Rule, Builder, BuildTool
from scripts.namespace import Namespace
import pytest
import re

def split(x):
    return re.split(r'\s+',x)

@pytest.fixture
def fake_project(tmp_path: Path):
    test_files = ['source_1']
    files = {}
    for i,name in enumerate(test_files):
        f = tmp_path/name
        f.write_text(f'test file #{i}')
        files[name] = f
    return dict(root=tmp_path,files=files)

@pytest.fixture
def buildtool1(fake_project):
    def rules(buildtool):
        buildtool.rules['rule1'] = Rule(
            command = '$a $in | tee $out',
        )
    def builders(buildtool):
        buildtool.builders['builder1'] = Builder(
            rule = 'rule1',
            a = 'echo',
        )
    buildtool = BuildTool(
        root = fake_project['root'],
        rules=[rules],
        builders=[builders],
    )
    return buildtool

def checkcmd(backend_out,cmd):
    __tracebackhide__ = True
    passed = False
    for line in backend_out.splitlines():
        if cmd[0] in line:
            if split(line)[1:] == cmd:
                passed = True
                break
    if not passed:
        pytest.fail(f'Command "{" ".join(cmd)}" not found in backend output\nBackend output:\n{backend_out}')

    #pytest.param({},{},'a_val',KeyError,id='undefined_var'),
    #pytest.param({'a':lambda b: b + '_lambda'},{},'b_call_lambda',KeyError,id='lambda_builder_var_from_call_var_missing_input'),
    #pytest.param({},{'a':lambda b: b + '_lambda'},'b_builder_lambda',KeyError,id='lambda_call_var_from_builder_var_missing_input'),
    #pytest.param({'a':lambda a: a + '_lambda'},{'a':lambda a: a + '_lambda_call'},'a_lambda_call_lambda',KeyError,id='lambda_builder_var_from_lambda_call_var'),

@pytest.mark.parametrize("builder_args,call_args,expected_a_val", [
    pytest.param({'a':'a_builder'},{},'a_builder',id='builder_defined_var'),
    pytest.param({},{'a':'a_call'},'a_call',id='call_defined_var'),
    pytest.param({'a':'a_$b'},{'b':'b_call'},'a_b_call',id='builder_var_from_call_var'),
    pytest.param({'b':'b_builder'},{'a':'a_$b'},'a_b_builder',id='call_var_from_builder_var'),
    pytest.param({'a':'a_$b','b':'b_builder'},{},'a_b_builder',id='builder_var_from_builder_var'),
    pytest.param({},{'a':'a_$b','b':'b_call'},'a_b_call',id='call_var_from_call_var'),
])
def test_build(builder_args, call_args, expected_a_val, fake_project, capfd):
    def rules(buildtool):
        buildtool.rules['rule1'] = Rule(
            command = '$a $in $out',
        )
    def builders(buildtool):
        buildtool.builders['builder1'] = Builder(
            rule = 'rule1',
            **builder_args,
        )
    buildtool = BuildTool(
        root = fake_project['root'],
        rules=[rules],
        builders=[builders],
    )
    target = buildtool.builder1(
        source = '$source_dir/source_1',
        target = '$target_dir/target_1',
        **call_args,
    )
    ref_target = 'target_1'
    assert target == ref_target
    writer = buildtool.run(ninja_opts='-n')
    checkcmd(capfd.readouterr().out,[expected_a_val,str(fake_project["files"]["source_1"]),ref_target])

def test_build_log_variable(buildtool1, fake_project, capfd):
    target = buildtool1.builder1(
        source = '$source_dir/source_1',
        target = 'target_1',
        log = 'foo.log'
    )
    ref_target = 'target_1'
    assert target == [ref_target,'foo.log']
    writer = buildtool1.run(ninja_opts='-n')
    checkcmd(capfd.readouterr().out,['echo',str(fake_project["files"]["source_1"]),'|','tee','target_1','2>&1','|','tee','foo.log'])

def test_build_unused_variable(fake_project):
    def rules(buildtool):
        buildtool.rules['rule1'] = Rule(
            command = '$a $in',
        )
    def builders(buildtool):
        buildtool.builders['builder1'] = Builder(
            rule = 'rule1',
            a = 'ech$b',
            b = 'o',
        )
    buildtool = BuildTool(
        root = fake_project['root'],
        rules=[rules],
        builders=[builders],
    )
    target = buildtool.builder1(
        source = '$source_dir/source_1',
        target = 'foo.log',
    )
    writer = buildtool.run(ninja_opts='-n')
    ninja = (fake_project['root']/'work/build.ninja').read_text()
    for line in ninja.splitlines():
        if re.search(r'b\s*=',line):
            assert False, line

def test_build_cwd(buildtool1, fake_project, capfd):
    target = buildtool1.builder1(
        source = '$source_dir/source_1',
        target = 'foo.log',
        cwd = 'subwork',
    )
    ref_target = 'subwork/foo.log'
    assert target == ref_target
    writer = buildtool1.run(ninja_opts='-n')
    checkcmd(capfd.readouterr().out,['echo',str(fake_project["files"]["source_1"]),'|','tee',ref_target])

def test_build_cwd_absolute_target(buildtool1, fake_project, capfd):
    target = buildtool1.builder1(
        source = '$source_dir/source_1',
        target = '$target_dir/subwork/foo.log',
        cwd = 'subwork',
    )
    ref_target = 'subwork/foo.log'
    assert target == ref_target
    writer = buildtool1.run(ninja_opts='-n')
    checkcmd(capfd.readouterr().out,['echo',str(fake_project["files"]["source_1"]),'|','tee',ref_target])

def test_build_implicit_dependency(buildtool1, fake_project, capfd):
    target = buildtool1.builder1(
        source = '$source_dir/source_1',
        target = 'target_1',
        implicit_source = '$target_dir/implicit_1',
    )
    implicit = buildtool1.builder1(
        source = '$source_dir/source_1',
        target = 'implicit_1',
    )
    ref_target = 'target_1'
    assert target == ref_target
    ref_implicit = 'implicit_1'
    assert implicit == ref_implicit
    writer = buildtool1.run(ninja_opts='-n')
    out = capfd.readouterr().out
    checkcmd(out,['echo',str(fake_project["files"]["source_1"]),'|','tee',ref_target])
    checkcmd(out,['echo',str(fake_project["files"]["source_1"]),'|','tee',ref_implicit])

def test_resolve_out_path(buildtool1):
    builder = buildtool1.builder1
    namespace = Namespace(**{
        'cwd': '$target_dir/subwork',
        'source_dir': builder.source_dir,
        'target_dir': builder.target_dir
    })
    resolve_out_path = builder.resolve_out_path(namespace)
    target = '$target_dir/subwork/target_1'
    assert str(resolve_out_path(target)) == 'subwork/target_1'

def test_resolve_out_path_relative(buildtool1):
    builder = buildtool1.builder1
    namespace = Namespace(**{
        'cwd': '$target_dir/subwork',
        'source_dir': builder.source_dir,
        'target_dir': builder.target_dir
    })
    resolve_out_path = builder.resolve_out_path(namespace)
    target = 'subwork/target_1'
    assert str(resolve_out_path(target)) == 'subwork/target_1'

