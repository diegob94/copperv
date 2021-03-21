import sys
from pathlib import Path
sys.path.append(str(Path(__file__).resolve().parent.parent))
from scripts.namespace import Template, Namespace, Node
import pytest

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

def test_template_substitute_basic():
    template = Template('test $test')
    t = template.substitute(test = 'value')
    assert t == 'test value'

def test_template_substitute_exclude():
    template = Template('test $test $excludeme')
    t = template.substitute(test = 'value')
    assert t == 'test value $excludeme'

def test_template_substitute_unused_var():
    template = Template('test $test')
    t = template.substitute(test = 'value', foo = 'useless')
    assert t == 'test value'

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
def test_collect_namespaces_priority(namespaces,expected):
    r = Namespace.collect(*namespaces)
    assert r.to_dict() == expected

@pytest.mark.parametrize("namespace,exclude,expected", [
    pytest.param({},[],{},id='empty'),
    pytest.param({'a':1},[],{'a':1},id='identity'),
    pytest.param({'a':'a_$b','b':1},[],{'a':'a_1','b':1},id='simple'),
    pytest.param({'a':'a_$b'},['b'],{'a':'a_$b'},id='simple_exclude'),
    pytest.param({'a':'a_$b','b':1},['b'],{'a':'a_$b','b':1},id='simple_exclude_existing'),
    pytest.param({'a':'a_$b','b':'b_$c','c':1},[],{'a':'a_b_1','b':'b_1','c':1},id='double'),
])
def test_resolve_dependencies(namespace,exclude,expected):
    namespace = Namespace(namespace)
    r = namespace.resolve(exclude)
    assert r == expected

@pytest.mark.parametrize("namespace", [
    pytest.param({'a':'$b'},id='missing_key'),
    pytest.param({'a':'a_$b','b':'b_$a'},id='circular_dependency_double'),
    pytest.param({'a':'$b','b':'$c','c':'$a'},id='circular_dependency_triple'),
    pytest.param({'a':'a_$a'},id='self_dependency'),
])
def test_resolve_dependencies_errors(namespace):
    namespace = Namespace(namespace)
    with pytest.raises(KeyError):
        namespace.resolve()

def test_namespace_in():
    ns = Namespace({'a':1})
    r = 'a' in ns
    assert r == True
    r = 'b' in ns
    assert r == False

def test_namespace_getelem():
    ns = Namespace({'a':1,'b':2})
    r = ns['a']
    assert r == Node(name='a', value=1, deps=None)
    r = ns['b']
    assert r == Node(name='b', value=2, deps=None)

