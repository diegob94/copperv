import sys
from pathlib import Path
sys.path.append(str(Path(__file__).resolve().parent.parent))
from scripts.build_tools import Rule, Builder, BuildTool, get_lambda_arg_names, Template, collect_namespaces, resolve_dependencies
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
        pytest.fail(f'Command "{" ".join(cmd)}" not found in backend output\nBackend output:\n{backend_out}')

def test_get_lambda_arg_names():
    foo = lambda a, b, c: a + b + c
    r = get_lambda_arg_names(foo)
    assert r == ('a', 'b', 'c')
    foo = lambda a, b = 2: a + b
    r = get_lambda_arg_names(foo)
    assert r == ('a', 'b')
    foo = lambda a = 1, b = 2: a + b
    r = get_lambda_arg_names(foo)
    assert r == ('a', 'b')

@pytest.mark.parametrize("builder_args,call_args,expected_a_val,expected_exception", [
    pytest.param({'a':'a_builder'},{},'a_builder',None,id='builder_defined_var'),
    pytest.param({},{},'a_val',KeyError,id='undefined_var'),
    pytest.param({},{'a':'a_call'},'a_call',None,id='call_defined_var'),
    pytest.param({'a':'a_builder'},{'a':'a_call'},'a_call',None,id='builder_and_call_defined_var'),
    pytest.param({'a':lambda b: b + '_lambda'},{'b':'b_call'},'b_call_lambda',None,id='lambda_builder_var_from_call_var'),
    pytest.param({'b':'b_builder'},{'a':lambda b: b + '_lambda'},'b_builder_lambda',None,id='lambda_call_var_from_builder_var'),
    pytest.param({'a':lambda b: b + '_lambda'},{},'b_call_lambda',KeyError,id='lambda_builder_var_from_call_var_missing_input'),
    pytest.param({},{'a':lambda b: b + '_lambda'},'b_builder_lambda',KeyError,id='lambda_call_var_from_builder_var_missing_input'),
    pytest.param({'a':lambda a: a + '_lambda'},{'a':'a_call'},'a_call_lambda',None,id='lambda_builder_var_from_call_var_same_name'),
    pytest.param({'a':lambda a: a + '_lambda'},{'a':lambda a: a + '_lambda_call'},'a_lambda_call_lambda',KeyError,id='lambda_builder_var_from_lambda_call_var'),
    pytest.param({'a':lambda b: b + '_lambda','b':'b_builder'},{},'b_builder_lambda',None,id='lambda_builder_var_from_builder_var'),
    pytest.param({},{'a':lambda b: b + '_lambda','b':'b_call'},'b_call_lambda',None,id='lambda_call_var_from_call_var'),
])
def test_simple_build(builder_args, call_args, expected_a_val, expected_exception, fake_project: Path, capfd):
    def rules(buildtool):
        buildtool.rules['rule1'] = Rule(
            command = '$a $in $out',
            variables = ['a'],
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
    call = lambda: buildtool.builder1(
        source = 'source_1',
        target = 'target_1',
        **call_args,
    )
    if expected_exception is not None:
        with pytest.raises(expected_exception):
            target = call()
        return None
    else:
        target = call()
    assert target == 'target_1'
    writer = buildtool.run(ninja_opts='-n')
    checkcmd(capfd,[expected_a_val,str(fake_project["files"]["source_1"]),'target_1'])

@pytest.mark.parametrize("template,var_names", [
    pytest.param('test',[],id='no_vars'),
    pytest.param('test $a $b',['a','b'],id='simple_vars'),
    pytest.param('test ${a} ${b}',['a','b'],id='braced_vars'),
    pytest.param('test ${a}_b',['a'],id='underscore'),
    pytest.param('test $a/b',['a'],id='path'),
])
def test_template_get_names(template, var_names):
    template = Template(template)
    assert len(template.names) == len(var_names)
    assert template.names == var_names

def test_expand_template_basic():
    template = Template('test $test')
    t = template.substitute(test = 'value')
    assert t == 'test value'

def test_expand_template_exclude():
    template = Template('test $test $excludeme')
    t = template.substitute(test = 'value')
    assert t == 'test value $excludeme'

@pytest.mark.parametrize("namespaces,expected", [
    pytest.param(({},{}),{},id='empty'),
    pytest.param(({},{'a':1}),{'a':1},id='identity'),
    pytest.param(({'a':1},{}),{'a':1},id='identity_inv'),
    pytest.param(({'a':1},{'b':2}),{'a':1,'b':2},id='exclusive'),
    pytest.param(({'b':2},{'a':1}),{'a':1,'b':2},id='exclusive_inv'),
    pytest.param(({'a':1},{'a':2}),{'a':1},id='precedence'),
    pytest.param(({'a':2},{'a':1}),{'a':2},id='precedence_inv'),
    pytest.param(({'a':1,'b':2},{'a':3,'c':4}),{'a':1,'b':2,'c':4},id='all'),
    pytest.param(({'a':3,'c':4},{'a':1,'b':2}),{'a':3,'b':2,'c':4},id='all_inv'),
])
def test_resolve_namespace_priority(namespaces,expected):
    r = collect_namespaces(*namespaces)
    assert r == expected

@pytest.mark.parametrize("namespace,exclude,expected", [
    pytest.param({},[],{},id='empty'),
    pytest.param({'a':1},[],{'a':1},id='identity'),
    pytest.param({'a':'a_$b','b':1},[],{'a':'a_1','b':1},id='simple'),
    pytest.param({'a':'a_$b'},['b'],{'a':'a_$b'},id='simple_exclude'),
    pytest.param({'a':'a_$b','b':1},['b'],{'a':'a_$b','b':1},id='simple_exclude_existing'),
    pytest.param({'a':'a_$b','b':'b_$c','c':'1'},[],{'a':'a_b_1','b':'b_1','c':1},id='double'),
])
def test_resolve_dependencies(namespace,exclude,expected):
    r = resolve_dependencies(namespace,exclude)
    assert r == expected

@pytest.mark.parametrize("namespace", [
    pytest.param({'a':'$b'},id='missing_key'),
    pytest.param({'a':'a_$b','b':'b_$a'},id='circular_dependency'),
])
def test_resolve_dependencies_errors(namespace):
    with pytest.raises(KeyError):
        r = resolve_dependencies(namespace)

