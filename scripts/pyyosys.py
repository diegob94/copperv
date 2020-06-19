from pathlib import Path
from dataclasses import dataclass

import orjson

class PyYosys:
    @property
    def fields(self):
        return tuple(self.__dataclass_fields__.keys())

@dataclass
class Module(PyYosys):
    attributes: dict
    ports: dict
    cells: dict
    netnames: dict

@dataclass
class Instance(PyYosys):
    modules: dict
    module_name: str
    children: dict
    attributes: dict
    @property
    def module(self):
        return self.modules[self.module_name]

json = Path('synth.json').read_text()
design = orjson.loads(json)
metadata = dict(json_creator = design['creator'])

modules = {}
top = None
for name,contents in design['modules'].items():
    save_as_attribute = ['parameter_default_values']
    for k in save_as_attribute:
        if k in contents:
            v = contents.pop(k)
            contents['attributes'][k] = v
    modules[name] = Module(**contents)
    if 'top' in modules[name].attributes:
        children = {}
        attributes = dict(type = 'hierarchical') 
        top = Instance(module_name = name, modules = modules, attributes = attributes, children = children)

def construct_tree(root):
    for cell_name, v in root.module.cells.items():
        module_name = v['type']
        children = {}
        if module_name in root.modules:
            attributes = dict(type = 'hierarchical') 
        else:
            attributes = dict(type = 'leaf') 
        root.children[cell_name] = Instance(module_name = module_name, modules = root.modules, attributes = attributes, children = children)
        if root.children[cell_name].attributes['type'] == 'hierarchical':
            construct_tree(root.children[cell_name])

construct_tree(top)

hier = [k for k,v in top.children.items() if v.attributes['type'] == 'hierarchical']

