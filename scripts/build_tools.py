from pathlib import Path
import enum
import inspect
import subprocess as sp
import inspect
import dataclasses
import logging
from string import Template

import ninja

@enum.unique
class InternalTarget(enum.Enum):
    LOG_FILE = enum.auto()

class BuildTool:
    LOG_FILE = InternalTarget.LOG_FILE
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
    def __init__(self, command, depfile = None, variables = {}, log = None, log_is_target = False):
        self.depfile = depfile
        self.variables = variables
        self.is_configured = False
        self.log = log
        if self.log is not None:
            self.command = f'{command} 2>&1 | tee {self.log}'
        else:
            self.command = command
        self.log_is_target = log_is_target
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
    def append_to_command(self, value):
        self.command = self.command + value

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
    def configure(self, name, buildtool):
        self._buildtool = buildtool
        self._name = name
        self.is_configured = True
    @property
    def name(self):
        if not self.is_configured:
            raise ValueError("Builder not configured")
        return self._name
    @property
    def buildtool(self) -> BuildTool:
        if not self.is_configured:
            raise ValueError("Builder not configured")
        return self._buildtool
    @property
    def rule(self) -> Rule:
        return self.buildtool.rules[self.rule_name]
    @property
    def writer(self):
        return self.buildtool.writer
    @property
    def target_dir(self):
        return self.buildtool.target_dir
    def __call__(self, target, source, log = None, **kwargs):
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
        ## expand target
        save_log = False
        if target is self.buildtool.LOG_FILE:
            save_log = True
            target_is_log = True
            if log is not None:
                preproc_target = log
            else:
                raise ValueError("Value for target is LOG_FILE but log argument missing")
        else:
            target_is_log = False
            preproc_target = target
        source = as_list(source)
        preproc_target = as_list(preproc_target)
        if not target_is_log and log is not None:
            save_log = True
            preproc_target.insert(0,log)
        actual_target = []
        for src,tgt in zip(source,preproc_target):
            if callable(tgt):
                params = inspect.signature(tgt).parameters
                if len(params) == 2:
                    actual_target.append(tgt(self.target_dir,Path(src)))
                elif len(params) == 1:
                    actual_target.append(tgt(self.target_dir))
                else:
                    raise ValueError("Lambda has wrong number of arguments, \
                            signature should be lambda target_dir, input_file: \
                            or lambda target_dir:")
            else:
                actual_target.append(tgt)
        if save_log:
            self.rule.append_to_command(f' 2>&1 | tee {actual_target[0]}')
        self.writer.rule(self.rule)
        self.writer.build(self.rule,actual_target,source,actual_variables,actual_implicit)
        return actual_target[0] if len(actual_target) == 1 else actual_target

