from pathlib import Path
from dataclasses import dataclass
import logging

import orjson

__all__ = ['DesignTree']

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
    name: str
    children: dict
    attributes: dict
    @property
    def module(self):
        return self.modules[self.module_name]

FORMAT = '%(asctime)s:%(levelname)s: %(message)s'
logging.basicConfig(format = FORMAT)
logger = logging.getLogger(__name__)
logger.setLevel("DEBUG")
logger.setLevel("INFO")

class DesignTree:
    def __init__(self, json):
        json = Path(json).read_text()
        design = orjson.loads(json)
        self.metadata = dict(json_creator = design['creator'])
        modules = {}
        self.top = None
        for name,contents in design['modules'].items():
            logger.debug(f'Processing json modules: {name}')
            save_as_attribute = ['parameter_default_values']
            for k in save_as_attribute:
                if k in contents:
                    v = contents.pop(k)
                    contents['attributes'][k] = v
            modules[name] = Module(**contents)
            if 'top' in modules[name].attributes:
                children = {}
                attributes = dict(type = 'nonleaf') 
                self.top = Instance(name = name, module_name = name, modules = modules, attributes = attributes, children = children)

        logger.debug(f'Processing json modules: done\ntop: {None if self.top is None else self.top.module_name}')
        assert self.top is not None, "No top module found. Yosys 'synth -top $top_module' option required."
        logger.debug('Constructing tree')
        self.construct_tree(self.top)
        logger.debug('Constructing tree done')
    def construct_tree(self, root):
        for cell_name, v in root.module.cells.items():
            module_name = v['type']
            children = {}
            if module_name in root.modules:
                attributes = dict(type = 'nonleaf')
            else:
                attributes = dict(type = 'leaf')
            attributes.update(v['attributes'])
            root.children[cell_name] = Instance(name = cell_name, module_name = module_name, modules = root.modules, attributes = attributes, children = children)
            if root.children[cell_name].attributes['type'] == 'nonleaf':
                self.construct_tree(root.children[cell_name])
    def map_tree_leafs(self, funct):
        res = []
        self._map_tree_leafs(self.top, funct, res)
        return res
    def _map_tree_leafs(self, root, funct, res):
        if root.attributes['type'] == 'leaf':
            r = funct(root)
            if r is not None:
                res.append(r)
            return None
        for child in root.children.values():
            self._map_tree_leafs(child, funct, res)


#hier = [k for k,v in top.children.items() if v.attributes['type'] == 'nonleaf']
#print(hier)

