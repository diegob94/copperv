import io
from pathlib import Path
import subprocess as sp
import ninja
from string import Template
import inspect
import dataclasses

def get_root():
    main = inspect.stack()[-1][1]
    return Path(main).parent.absolute()

def run(cmd):
    #print(cmd)
    r = sp.run(cmd,shell=True,capture_output=True,check=True,encoding='utf-8').stdout.strip()
    #print(r)
    return r

class Rule:
    def __init__(self, command, depfile = None, variables = {}):
        self.command = command
        self.depfile = depfile
        self.variables = variables
        self.is_configured = False
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
    outputs: str
    rule: str
    inputs: str = None
    variables: dict = None

class Writer:
    def __init__(self, output_path, target_dir, source_dir):
        self.output_path = output_path
        self.rules = []
        self.builds = []
        self.source_dir = Path(source_dir).resolve()
        self.target_dir = Path(target_dir).resolve()
    def rule(self, rule):
        new = RuleParams(
            command = rule.command,
            name = rule.name,
            depfile = rule.depfile,
        )
        print(new)
        self.rules.append(new)
    def build(self, rule, target, source, variables):
        new = BuildParams(
            outputs = str(target),
            rule = rule.name,
            inputs = str(source),
            variables = variables
        )
        print(new)
        self.builds.append(new)
    def write(self):
        print(self.rules)
        print(self.builds)

class NinjaWriter(Writer):
    def __init__(self, target_dir, source_dir):
        super().__init__(target_dir/'build.ninja',target_dir,source_dir)
    def write(self):
        with self.output_path.open('w') as f:
            writer = ninja.Writer(f)
            writer.comment("Rules")
            for rule in self.rules:
                writer.rule(**rule.to_dict())
            writer.newline()
            writer.comment("Build targets")
            for build in self.builds:
                writer.build(**build.to_dict())
            writer.newline()

class Builder:
    def __init__(self, rule, kwargs = [], **variables):
        self.rule_name = rule
        self.variables = variables
        self.kw = kwargs
        self.is_configured = False
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
        build_variables = {}
        for name,value in self.variables.items():
            if callable(value):
                build_variables[name] = value(**kwargs)
            else:
                build_variables[name] = value
        self.writer.rule(self.rule)
        if isinstance(source, str):
            source = [source]
        if isinstance(target, str) or callable(target):
            target = [target]
        target = [tgt if not callable(tgt) else tgt(self.target_dir,Path(src)) for src,tgt in zip(source,target)]
        for src,tgt in zip(source,target):
            self.writer.build(self.rule,tgt,src,build_variables)
        return target

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

