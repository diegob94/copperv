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

#class MyTemplate(Template):
#    def __init__(self,*args, **kwargs):
#        super().__init__(*args, **kwargs)
#        self.var_names = self.get_var_names()
#    def get_var_names(self):
#        var_names= []
#        for i in self.pattern.finditer(self.template):
#            i = i.groupdict()
#            if i['named'] is not None:
#                var_names.append(i['named'])
#            elif i['braced'] is not None:
#                var_names.append(i['braced'])
#        return var_names
#
#class Environment:
#    def __init__(self, _builders={},**kwargs):
#        self.vars = dict(kwargs)
#        self.builders = dict(_builders)
#        self.subst()
#        Path(self['build_dir']).mkdir(exist_ok='True')
#        self.writer = NinjaWriter()
#    def __setitem__(self,key,value):
#        self.vars[key] = value
#    def __contains__(self, key):
#        return key in self.vars
#    def __getitem__(self,key):
#        return self.vars[key]
#    def items(self):
#        return self.vars.items()
#    def keys(self):
#        return self.var.keys()
#    def translate_path(self, path):
#        return Path(self['build_dir'])/Path(path).relative_to(self['root'])
#    def _subst_var(self, name, template):
#        try:
#            s = MyTemplate(template).substitute(**self.vars)
#        except KeyError as e:
#            raise KeyError(f'Variable "{e.args[0]}" not found while expanding "{name} = {template}"') from e
#        if s == template or not '$' in s:
#            return s
#        return self.subst_var(name, s)
#    def subst_var(self, name, template):
#        if isinstance(template, str):
#            template = [template]
#        r = [self._subst_var(name, t) for t in template]
#        if len(r) == 1:
#            return r[0]
#        return r
#    def subst(self):
#        self.vars = {k:self.subst_var(k, v) for k,v in self.items()}
#    def copy(self, **kwargs):
#        builders = dict(_builders = self.builders) if hasattr(self, 'builders') else {}
#        new_env = Environment(**builders,**self.vars,**kwargs)
#        for b in new_env.builders.values():
#            b.set_env(new_env)
#        return new_env
#    def addBuilder(self, **kwargs):
#        for key, value in kwargs.items():
#            self.builders[key] = value
#            self.builders[key].write_rule(key)
#    def __getattr__(self, key):
#        if key != 'builders' and key in self.builders:
#            return self.builders[key]
#        return self.__getattribute__(key)
#    def __repr__(self):
#        kwargs = dict(_builder=self.builders,**self.vars)
#        args = [f'{k}={repr(v)}' for k,v in kwargs.items()]
#        temp = ",".join(args)
#        return f'Environment({temp})'
#    def write(self):
#        ninja_path = Path(self['build_dir'])/'build.ninja'
#        self.writer.write(ninja_path)
#
#class SingletonMeta(type):
#    _instances = {}
#    def __call__(cls, *args, **kwargs):
#        if cls not in cls._instances:
#            instance = super().__call__(*args, **kwargs)
#            cls._instances[cls] = instance
#        return cls._instances[cls]
#
#class NinjaWriter(metaclass=SingletonMeta):
#    def __init__(self):
#        self.fd = io.StringIO()
#        self.writer = ninja.Writer(self.fd)
#        self.ninja_vars = ['in','out']
#    def close(self):
#        self.fd.close()
#    def __getattr__(self, key):
#        if key != 'writer':
#            return getattr(self.writer,key)
#        return self.__getattribute__(key)
#    def filter_ninja_vars(self, var_list):
#        return [i for i in var_list if not i in self.ninja_vars]
#    def get_command_vars(self, command):
#        command_vars = MyTemplate(command).var_names
#        return self.filter_ninja_vars(command_vars)
#    def write(self,ninja_path):
#        ninja_path.write_text(self.fd.getvalue())
#
#class Builder:
#    def __init__(self, command, depfile = None, **kwargs):
#        self.command = command
#        self.depfile = depfile
#        self.writer = NinjaWriter()
#        self.env = None
#        self.name = None
#        self.command_vars_names = self.writer.get_command_vars(command)
#        print(self.command_vars_names)
#        self.command_vars = {k:"" for k in self.command_vars_names}
#        self.command_vars.update(kwargs)
#    def __repr__(self):
#        kwargs = self.get_kwargs()
#        args = [f'{k}={repr(v)}' for k,v in kwargs.items()]
#        temp = ",".join(args)
#        return f'Builder({temp})'
#    def get_kwargs(self):
#        kwargs = dict(command = self.command)
#        if self.depfile is not None:
#            kwargs['depfile'] = self.depfile
#        return kwargs
#    def set_env(self, env):
#        self.env = env
#    def write_rule(self, name):
#        self.name = name
#        rule_kwargs = self.get_kwargs()
#        self.writer.rule(self.name, **rule_kwargs)
#    def __call__(self, target, source, inc_dir):
#        self.inc_dir = inc_dir
#        if isinstance(self.inc_dir,str):
#            self.inc_dir = [self.inc_dir]
#        self.preprocess()
#        for k in self.ninja_vars:
#            self.writer.variable(k,getattr(self,k))
#        if isinstance(source, str):
#            source = [source]
#        source = [Path(src).resolve() for src in source]
#        if callable(target):
#            target = [Path(target(src)).resolve() for src in source]
#        for src,tgt in zip(source,target):
#            src = str(src)
#            tgt = str(tgt)
#            self.writer.build(tgt,self.name,src)
#        return target
#    def preprocess(self):
#        self.cflags += ''.join([f' -I{i}' for i in self.inc_dir])
