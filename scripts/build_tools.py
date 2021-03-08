from pathlib import Path
import datetime
import enum
import inspect
import subprocess as sp
import dataclasses
import logging
from string import Template

import scripts.ninja_syntax as ninja

@enum.unique
class InternalTarget(enum.Enum):
    LOG_FILE = enum.auto()

class BuildTool:
    @enum.unique
    class Writers(enum.Enum):
        NINJA = enum.auto()
        TEST = enum.auto()
    LOG_FILE = InternalTarget.LOG_FILE
    def __init__(self, root, rules, builders, writer = Writers.NINJA):
        self.root = root
        self.target_dir = self.root / 'work'
        self.target_dir.mkdir(exist_ok=True)
        self.rules = {}
        self.builders = {}
        if writer == self.Writers.NINJA:
            self.writer = NinjaWriter(self.target_dir,self.root)
        else:
            self.writer = Writer(None,None,None,'test_writer')
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
        self.writer.variable('root',self.root)
        return self.writer.write()
    def __getattr__(self, key):
        if key != 'builders' and key in self.builders:
            return self.builders[key]
        return self.__getattribute__(key)
    def run(self, default_target = None, ninja_opts = None):
        if default_target is not None:
            self.writer.default(default_target)
        cmd = self.writer.command
        if ninja_opts is not None:
            cmd = f'{cmd} {ninja_opts}'
        r = self.write_script()
        try:
            print(cmd)
            sp.run(cmd,shell=True,check=True,encoding='utf-8',cwd=self.target_dir)
        except sp.CalledProcessError:
            pass
        return r

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
    elif x is None:
        return []
    else:
        return x

def expand_list(variables, **kwargs):
    v = {k:v for k,v in enumerate(variables)}
    r = expand_variables(v, **kwargs)
    return [r[i] for i in range(len(variables))]

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
    def __init__(self, command, depfile = None, variables = {}, log = None, no_output = False, pool = None):
        self.depfile = depfile
        self.variables = variables
        self.is_configured = False
        self.log = log
        self.command = command
        if no_output:
            self.append_to_command('; date > $out')
        if self.log is not None:
            self.save_log(self.log)
        self.pool = pool
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
    def save_log(self,log_file=None):
        if log_file is None:
            log_file = '$out'
        self.log = log_file
        self.append_to_command(f' 2>&1 | tee {self.log}')

class WriterParams:
    def replace_root(self,d,root):
        if isinstance(d,dict):
            return {ik:self.replace_root(i,root) for ik,i in d.items()}
        elif isinstance(d,list):
            return [self.replace_root(i,root) for i in d]
        elif d is None:
            return None
        else:
            return d.replace(root,'${root}')
    def to_dict(self,root = None):
        d = dataclasses.asdict(self)
        if root is not None:
            root = str(root)
            replaced = self.replace_root(d,root)
        else:
            replaced = d
        return replaced

@dataclasses.dataclass
class VariableParams(WriterParams):
    key: str
    value: str

@dataclasses.dataclass
class RuleParams(WriterParams):
    name: str
    command: str
    depfile: str = None
    pool: str = None

@dataclasses.dataclass
class BuildParams(WriterParams):
    outputs: list
    rule: str
    inputs: list = None
    variables: dict = None
    implicit: list = None
    implicit_outputs: list = None
    pool: str = None

@dataclasses.dataclass
class DefaultParams(WriterParams):
    paths: list = None

class Writer:
    def __init__(self, output_path, target_dir, source_dir, build_command):
        self.output_path = output_path
        self.source_dir = None
        self.target_dir = None
        if source_dir is not None:
            self.source_dir = Path(source_dir).resolve()
        if target_dir is not None:
            self.target_dir = Path(target_dir).resolve()
        self.rules = {}
        self.builds = []
        self.variables = {}
        self.defaults = []
        self.logger = logging.getLogger(__name__)
        self.command = build_command
    def rule(self, rule):
        new = RuleParams(
            command = rule.command,
            name = rule.name,
            depfile = rule.depfile,
            pool = rule.pool,
        )
        self.logger.debug(f"new rule: {new}")
        self.rules[rule.name] = new
    def build(self, rule, target, source, variables, implicit, implicit_outputs, pool):
        new = BuildParams(
            outputs = stringify(target),
            rule = rule.name,
            inputs = stringify(source),
            variables = stringify(variables),
            implicit = flatten(stringify(implicit)),
            implicit_outputs=flatten(stringify(implicit_outputs)),
            pool = pool,
        )
        self.logger.debug(f"new build: {new}")
        self.builds.append(new)
    def variable(self, name, value):
        new = VariableParams(
            key = name,
            value = value,
        )
        self.logger.debug(f"new build: {new}")
        self.variables[name] = new
    def default(self, paths):
        new = DefaultParams(
            paths = stringify(paths),
        )
        self.logger.debug(f"new default: {new}")
        self.defaults.append(new)
    def write(self) -> "Writer":
        return self

class NinjaWriter(Writer):
    def __init__(self, target_dir, source_dir):
        super().__init__(target_dir/'build.ninja',target_dir,source_dir,'ninja -v')
    def write(self):
        with self.output_path.open('w') as f:
            writer = ninja.Writer(f)
            writer.comment(f"File generated by copperv build_tools.py on {datetime.datetime.now().astimezone().isoformat()}")
            writer.newline()
            if len(self.variables) > 0:
                writer.comment("Variables")
                for variable in self.variables.values():
                    writer.variable(**variable.to_dict())
                writer.newline()
            writer.comment("Rules")
            for rule in self.rules.values():
                writer.rule(**rule.to_dict(self.source_dir))
            writer.newline()
            writer.comment("Build statements")
            for build in self.builds:
                writer.build(**build.to_dict(self.source_dir))
            writer.newline()
            if len(self.defaults) > 0:
                writer.comment('Default targets')
                for default in self.defaults:
                    writer.default(**default.to_dict(self.source_dir))
                writer.newline()

class Builder:
    def __init__(self, rule, implicit = None, pool = None, kwargs = [], check_log = None, log = None, **variables):
        self.rule_name = rule
        self.variables = variables
        self.kw = kwargs
        self.is_configured = False
        self.logger = logging.getLogger(__name__)
        self.implicit = implicit
        self.pool = pool
        self.check_log = check_log
        self.log = log
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
    @property
    def root(self):
        return self.buildtool.root
    def check_variables(self, variables: dict):
        for name in self.rule.variables:
            if not name in variables.keys():
                raise KeyError(f'Rule variable "{name}" not defined')
    def __call__(self, target, source, implicit_target = None, log = None, check_log = None, **kwargs):
        self.logger.debug('begin')
        self.logger.debug(f"kwargs: {kwargs}")
        self.logger.debug(f"self.variables: {self.variables}")
        actual_variables = {}
        for name,value in self.variables.items():
            if callable(value):
                parameters = inspect.signature(value).parameters
                self.logger.debug(f'parameters: {parameters}')
                try:
                    input_values = {}
                    for k,v in parameters.items():
                        if v.kind == inspect.Parameter.VAR_KEYWORD:
                            if len(parameters) != 1:
                                raise TypeError(f'Builder "{self.name} variable "{name}" cannot use var keyword (**kwargs) and explicit args') from None
                            else:
                                input_values = kwargs
                        else:
                            input_values[k] = kwargs[k]
                except KeyError as e:
                    raise KeyError(f'Builder "{self.name}" variable "{name}" input "{k}" not found') from None
                actual_value = value(**input_values)
            else:
                actual_value = value
            actual_variables[name] = actual_value
        self.logger.debug(f"actual_variables: {actual_variables}")
        mod_variables_keys = set(kwargs.keys()).intersection(self.variables.keys())
        kwargs_keys = set(kwargs.keys()).difference(self.variables.keys())
        self.logger.debug(f"mod_variables_keys: {mod_variables_keys}")
        self.logger.debug(f"kwargs_keys: {kwargs_keys}")
        kwargs = {k:kwargs[k] for k in kwargs_keys}
        ## expand kwargs
        self.logger.debug(f"kwargs: {kwargs}")
        actual_kwargs = expand_variables(kwargs, target_dir=self.target_dir)
        self.logger.debug(f"actual_kwargs: {actual_kwargs}")
        ## expand variables
        self.logger.debug(f"self.variables: {self.variables}")
        actual_variables = expand_variables(self.variables, **actual_kwargs)
        self.logger.debug(f"actual_variables: {actual_variables}")
        mod_variables = expand_variables({k:actual_variables[k] for k in mod_variables_keys}, **actual_kwargs)
        actual_variables.update(mod_variables)
        self.logger.debug(f"actual_variables: {actual_variables}")
        ## expand implicit
        actual_implicit = None
        if self.implicit is not None:
            self.logger.debug(f"self.implicit: {self.implicit}")
            actual_implicit = expand_variables(dict(implicit=self.implicit), **actual_kwargs)['implicit']
            self.logger.debug(f"actual_implicit: {actual_implicit}")
        ## expand target
        source = [(self.root/i).resolve() for i in as_list(source)]
        log_in_target = False
        save_log = False
        explicit_target = []
        log_index = 0
        if log is not None:
            self.log = log
        for index,tgt in enumerate(as_list(target)):
            if tgt is self.buildtool.LOG_FILE:
                save_log = True
                log_in_target = True
                if self.log is not None:
                    temp_tgt = self.log
                    log_index = index
                else:
                    raise ValueError("Target is LOG_FILE but log argument missing")
            else:
                temp_tgt = tgt
            if callable(temp_tgt):
                new = temp_tgt(self.target_dir)
            else:
                new = temp_tgt
            explicit_target.append(new)
        implicit_target = as_list(implicit_target)
        if not save_log and self.log is not None:
            save_log = True
            implicit_target.insert(0,self.log)
        actual_implicit_target = expand_list(as_list(implicit_target),target_dir=self.target_dir)
        if save_log:
            if log_in_target:
                log_file = explicit_target[log_index]
            else:
                log_file = actual_implicit_target[0]
            self.rule.save_log(log_file)
            actual_variables['log'] = self.rule.log
        if check_log is not None:
            self.check_log = check_log
        if self.check_log is not None:
            self.rule.append_to_command(f'; {self.check_log}')
        self.check_variables(actual_variables)
        self.writer.rule(self.rule)
        self.writer.build(self.rule,explicit_target,source,actual_variables,actual_implicit,actual_implicit_target,self.pool)
        r = explicit_target[0] if len(explicit_target) == 1 else explicit_target
        self.logger.debug(f'return targets: {r}')
        return r

