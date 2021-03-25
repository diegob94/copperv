from pathlib import Path
import datetime
import enum
import subprocess as sp
import dataclasses
import logging
import string

import scripts.ninja_syntax as ninja
from scripts.namespace import Namespace

class BuildTool:
    @enum.unique
    class Writers(enum.Enum):
        NINJA = enum.auto()
        TEST = enum.auto()
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
    def __init__(self, command, depfile = None, log = None, no_output = False, pool = None):
        self.depfile = depfile
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
        root = self.source_dir
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
                writer.rule(**rule.to_dict(root))
            writer.newline()
            writer.comment("Build statements")
            for build in self.builds:
                writer.build(**build.to_dict(root))
            writer.newline()
            if len(self.defaults) > 0:
                writer.comment('Default targets')
                for default in self.defaults:
                    writer.default(**default.to_dict(root))
                writer.newline()

class Builder:
    def __init__(self, rule, implicit = None, pool = None, check_log = None, log = None, **kwargs):
        self.rule_name = rule
        self.variables = kwargs
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
    def source_dir(self):
        return self.buildtool.root
    def resolve_variable(self, value, **kwargs):
        return Namespace(key=value, **kwargs).resolve()['key']
    def __call__(self, target, source, implicit_target = None, log = None, check_log = None, **kwargs):
        ## kwargs classes:
        ### define rule variable
        ### modify self.variable
        ### input for self.variable
        namespace = Namespace.collect(self.variables,kwargs)
        variables = namespace.resolve()
        resolved_target = []
        for t in as_list(target):
            resolved = Path(self.resolve_variable(t, target_dir=self.target_dir))
            if resolved.suffix == '.log':
                self.rule.save_log()
            resolved_target.append(resolved)
        resolved_source = [self.resolve_variable(t, source_dir=self.source_dir) for t in as_list(source)]
        implicit = self.implicit
        implicit_outputs = [self.resolve_variable(t, target_dir=self.target_dir) for t in as_list(implicit_target)]
        pool = self.pool
        self.writer.rule(self.rule)
        self.writer.build(self.rule, resolved_target, resolved_source, variables, implicit, implicit_outputs, pool)
        r = [Path(t).relative_to(self.target_dir) for t in resolved_target + implicit_outputs]
        r = r[0] if len(r) == 1 else r
        self.logger.debug(f'return targets: {r}')
        return stringify(r)

