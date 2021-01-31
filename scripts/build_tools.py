from pathlib import Path
import subprocess as sp
import inspect
import dataclasses
import logging

import ninja

def get_root():
    main = inspect.stack()[-1][1]
    return Path(main).parent.absolute()

def run(cmd):
    #print(cmd)
    r = sp.run(cmd,shell=True,capture_output=True,check=True,encoding='utf-8').stdout.strip()
    #print(r)
    return r

def as_list(x):
    if (isinstance(x,Path)
    or isinstance(x,str)
    or callable(x)):
        return [x]
    else:
        return x

def expand_variables(variables, **kwargs):
    logger = logging.getLogger(__name__)
    logger.debug(f"variables: {variables}")
    expanded_variables = {}
    pp_kwargs = kwargs
    for name,rvalue in variables.items():
        actual_values = rvalue
        if callable(rvalue):
            actual_values = rvalue(**pp_kwargs)
        elif isinstance(rvalue, list):
            actual_values = []
            for value in rvalue:
                if callable(value):
                    actual_values.append(value(**pp_kwargs))
                else:
                    actual_values.append(value)
        expanded_variables[name] = stringify(actual_values)
    logger.debug(f"expanded_variables: {expanded_variables}")
    return expanded_variables

def stringify(value):
    if isinstance(value, list):
        return [stringify(i) for i in value]
    elif isinstance(value, dict):
        return {str(k):stringify(v) for k,v in value.items()}
    else:
        if value is not None:
            return str(value)
        else:
            return None

def flatten(x):
    if not isinstance(x,list):
        return x
    r = []
    for i in x:
        if isinstance(i,list):
            r.extend([j for j in flatten(i)])
        else:
            r.append(i)
    return r

class Rule:
    def __init__(self, command, depfile = None, variables = {}, log = None):
        self.depfile = depfile
        self.variables = variables
        self.is_configured = False
        self.log = log
        if self.log is not None:
            self.command = f'{command} 2>&1 | tee {self.log}'
        else:
            self.command = command
    def configure(self, name):
        self._name = name
        self.is_configured = True
    @property
    def name(self):
        if not self.is_configured:
            raise ValueError("Rule not configured")
        return self._name
    def __repr__(self):
        attrs = [f'{k}={repr(getattr(self,k))}' for k in ['command','depfile','variables','is_configured']]
        return f"Rule({', '.join(attrs)})"

class WriterParams:
    def to_dict(self):
        return dataclasses.asdict(self)

@dataclasses.dataclass
class VariableParams(WriterParams):
    key: str
    value: str

@dataclasses.dataclass
class RuleParams(WriterParams):
    name: str
    command: str
    depfile: str = None

@dataclasses.dataclass
class BuildParams(WriterParams):
    outputs: list
    rule: str
    inputs: list = None
    variables: dict = None
    implicit: list = None

class Writer:
    def __init__(self, output_path, target_dir, source_dir, command):
        self.output_path = output_path
        self.rules = {}
        self.builds = []
        self.source_dir = Path(source_dir).resolve()
        self.target_dir = Path(target_dir).resolve()
        self.command = command
        self.logger = logging.getLogger(__name__)
    def rule(self, rule):
        new = RuleParams(
            command = rule.command,
            name = rule.name,
            depfile = rule.depfile,
        )
        self.logger.debug(f"new rule: {new}")
        self.rules[rule.name] = new
    def build(self, rule, target, source, variables, implicit):
        new = BuildParams(
            outputs = stringify(target),
            rule = rule.name,
            inputs = stringify(source),
            variables = stringify(variables),
            implicit = flatten(stringify(implicit)),
        )
        self.logger.debug(f"new build: {new}")
        self.builds.append(new)
    def write(self):
        print(self.rules)
        print(self.builds)

class NinjaWriter(Writer):
    def __init__(self, target_dir, source_dir):
        super().__init__(target_dir/'build.ninja',target_dir,source_dir,'ninja -v')
    def write(self):
        with self.output_path.open('w') as f:
            writer = ninja.Writer(f)
            writer.comment("Rules")
            for rule in self.rules.values():
                writer.rule(**rule.to_dict())
            writer.newline()
            writer.comment("Build targets")
            for build in self.builds:
                writer.build(**build.to_dict())
            writer.newline()

class Builder:
    def __init__(self, rule, implicit = None, kwargs = [], **variables):
        self.rule_name = rule
        self.variables = variables
        self.kw = kwargs
        self.is_configured = False
        self.logger = logging.getLogger(__name__)
        self.implicit = implicit
    def configure(self, name, build):
        self._build = build
        self._name = name
        self.is_configured = True
    @property
    def name(self):
        if not self.is_configured:
            raise ValueError("Builder not configured")
        return self._name
    @property
    def build(self):
        if not self.is_configured:
            raise ValueError("Builder not configured")
        return self._build
    @property
    def rule(self):
        return self.build.rules[self.rule_name]
    @property
    def writer(self):
        return self.build.writer
    @property
    def target_dir(self):
        return self.build.target_dir
    def __call__(self, target, source, **kwargs):
        self.writer.rule(self.rule)
        ## expand target
        source = as_list(source)
        target = as_list(target)
        if self.rule.log is not None:
            target.append(self.rule.log)
        actual_target = []
        for src,tgt in zip(source,target):
            if callable(tgt):
                actual_target.append(tgt(self.target_dir,Path(src)))
            else:
                actual_target.append(tgt)
        ## expand kwargs
        self.logger.debug(f"kwargs: {kwargs}")
        actual_kwargs = expand_variables(kwargs, target_dir=self.target_dir)
        self.logger.debug(f"actual_kwargs: {actual_kwargs}")
        ## expand variables
        self.logger.debug(f"self.variables: {self.variables}")
        actual_variables = expand_variables(self.variables, **actual_kwargs)
        self.logger.debug(f"actual_variables: {actual_variables}")
        ## expand implicit
        actual_implicit = None
        if self.implicit is not None:
            self.logger.debug(f"self.implicit: {self.implicit}")
            actual_implicit = expand_variables(dict(implicit=self.implicit), **actual_kwargs)['implicit']
            self.logger.debug(f"actual_implicit: {actual_implicit}")
        self.writer.build(self.rule,actual_target,source,actual_variables,actual_implicit)
        return actual_target[0] if len(actual_target) == 1 else actual_target

class Build:
    def __init__(self, rules, builders):
        self.root = get_root()
        self.target_dir = self.root / 'work'
        self.target_dir.mkdir(exist_ok=True)
        self.rules = {}
        self.builders = {}
        self.writer = NinjaWriter(self.target_dir,self.root)
        if callable(rules):
            rules = [rules]
        if callable(builders):
            builders = [builders]
        for rule_factory in rules:
            rule_factory(self)
        for builder_factory in builders:
            builder_factory(self)
        for name,rule in self.rules.items():
            rule.configure(name)
        for name,builder in self.builders.items():
            builder.configure(name, self)
    def write_script(self):
        self.writer.write()
    def __getattr__(self, key):
        if key != 'builders' and key in self.builders:
            return self.builders[key]
        return self.__getattribute__(key)
    def run(self):
        self.write_script()
        try:
            sp.run(self.writer.command,shell=True,check=True,encoding='utf-8',cwd=self.target_dir)
        except sp.CalledProcessError:
            pass

