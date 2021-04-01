from typing import List
import dataclasses
import string
from collections.abc import Iterable
import logging

class Template(string.Template):
    def __init__(self,template,*args, **kwargs):
        super().__init__(str(template),*args, **kwargs)
        self.names = self.get_var_names()
    def get_var_names(self):
        var_names= []
        for i in self.pattern.finditer(self.template):
            i = i.groupdict()
            if i['named'] is not None:
                var_names.append(i['named'])
            elif i['braced'] is not None:
                var_names.append(i['braced'])
        return var_names
    def substitute(self, **kws):
        mapping = kws
        # Helper function for .sub()
        def convert(mo):
            # Check the most common path first.
            named = mo.group('named') or mo.group('braced')
            if named is not None:
                if named in mapping:
                    return str(mapping[named])
                else:
                    return mo[0]
            if mo.group('escaped') is not None:
                return self.delimiter
            if mo.group('invalid') is not None:
                self._invalid(mo)
            raise ValueError('Unrecognized named group in pattern',
                             self.pattern)
        return self.pattern.sub(convert, self.template)

class Namespace:
    def __init__(self, **variables: str):
        self._nodes = [Node(k,self.process_input(v),None) for k,v in variables.items()]
        self.logger = logging.getLogger(__name__)
    def process_input(self, v):
        r = v
        if not isinstance(v, str) and isinstance(v, Iterable):
            r = ' '.join([str(i) for i in v])
        return r
    @staticmethod
    def collect(*args):
        collected = {}
        for ns in args:
            for k,v in ns.items():
                if k in collected:
                    raise KeyError(f'Duplicated variable "{k}"')
                else:
                    collected[k] = v
        return Namespace(**collected)
    def resolve(self):
        self.logger.debug(f'before {self=}')
        self.process_deps()
        self.logger.debug(f'process {self=}')
        self.substitute_deps()
        self.logger.debug(f'substitute {self=}')
        r = self.to_dict()
        self.logger.debug(f'dict {r=}')
        return r
    def process_deps(self):
        for node in self._nodes:
            node.set_deps(self)
    def eval(self,value):
        self.resolve()
        self.logger.debug(f'resolve {self=}')
        node = Node('key',value,None)
        node.set_deps(self)
        self.logger.debug(f'set_deps {node=}')
        r = node.substitute_deps().value
        self.logger.debug(f'substitute_deps {node=}')
        self.logger.debug(f'substitute_deps {node.substitute_deps()=}')
        return r
    def substitute_deps(self):
        self._nodes = [node.substitute_deps() if not node.is_leaf else node for node in self._nodes]
    def __contains__(self, item):
        return item in self.to_dict()
    def __getitem__(self, key):
        for n in self._nodes:
            if n.name == key:
                return n
    def to_dict(self):
        return {i.name:i.value for i in self._nodes}
    def __str__(self):
        return str(self.to_dict())
    def __iter__(self):
        return self._nodes.__iter__()
    def append(self, node):
        self._nodes.append(node)
    def __repr__(self):
        return 'Namespace<'+str(self._nodes)+'>'
    @staticmethod
    def from_list(_nodes):
        ns = Namespace()
        ns._nodes = _nodes
        return ns
    def __len__(self):
        return len(self._nodes)

class Node:
    def __init__(self, name, value, deps = None):
        self.name = name
        self.value = value
        self.deps = deps
        if deps is None:
            self.deps = Namespace()
    def __str__(self):
        return f'Node<{self.name},{self.value},{self.deps}>'
    def __repr__(self):
        return f'Node({repr(self.name)},{repr(self.value)},{repr(self.deps)})'
    @property
    def template(self):
        return Template(self.value)
    @property
    def is_leaf(self):
        return len(self.deps) == 0
    def sanity_check(self):
        Node._sanity_check(self, [])
    @staticmethod
    def _sanity_check(root: 'Node', stack: 'List[Node]'):
        for dep in root.deps:
            if dep == root:
                raise KeyError(f'Variable depends on itself: {root.name}={root.value}')
            if dep in stack:
                #culprit = next(i for i in stack if i == dep)
                raise KeyError(f'Circular dependency in variable: {root.name}={root.value}')
            stack.append(root)
            Node._sanity_check(dep,stack)
    def substitute_deps(self) -> "Node":
        self.sanity_check()
        substituted_deps = Namespace()
        for dep in self.deps:
            temp = dep
            if not dep.is_leaf:
                temp = dep.substitute_deps()
            substituted_deps.append(temp)
        new_value = None
        if self.value is not None:
            new_value = self.template.substitute(**substituted_deps.to_dict())
        return Node(
            self.name,
            new_value,
            substituted_deps,
        )
    def set_deps(self, namespace: Namespace):
        dep_list = []
        for name in self.template.names:
            if name in namespace:
                dep_list.append(namespace[name])
            else:
                dep_list.append(Node(name,"",deps=[]))
        self.deps = Namespace.from_list(dep_list)

