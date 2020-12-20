import io
from pathlib import Path
import subprocess as sp
import ninja
from string import Template
import inspect

def get_root():
    main = inspect.stack()[-1][1]
    return str(Path(main).parent.absolute())

def run(cmd):
    #print(cmd)
    r = sp.run(cmd,shell=True,capture_output=True,check=True,encoding='utf-8').stdout.strip()
    #print(r)
    return r

class MyTemplate(Template):
    def __init__(self,*args, **kwargs):
        super().__init__(*args, **kwargs)
        self.var_names = self.get_var_names()
    def get_var_names(self):
        var_names= []
        for i in self.pattern.finditer(self.template):
            i = i.groupdict()
            if i['named'] is not None:
                var_names.append(i['named'])
            elif i['braced'] is not None:
                var_names.append(i['braced'])
        return var_names

class Environment:
    def __init__(self, _builders={},**kwargs):
        self.vars = dict(kwargs)
        self.builders = dict(_builders)
        self.subst()
        Path(self['build_dir']).mkdir(exist_ok='True')
        self.writer = NinjaWriter()
    def __setitem__(self,key,value):
        self.vars[key] = value
    def __contains__(self, key):
        return key in self.vars
    def __getitem__(self,key):
        return self.vars[key]
    def items(self):
        return self.vars.items()
    def keys(self):
        return self.var.keys()
    def translate_path(self, path):
        return Path(self['build_dir'])/Path(path).relative_to(self['root'])
    def _subst_var(self, name, template):
        try:
            s = MyTemplate(template).substitute(**self.vars)
        except KeyError as e:
            raise KeyError(f'Variable "{e.args[0]}" not found while expanding "{name} = {template}"') from e
        if s == template or not '$' in s:
            return s
        return self.subst_var(name, s)
    def subst_var(self, name, template):
        if isinstance(template, str):
            template = [template]
        r = [self._subst_var(name, t) for t in template]
        if len(r) == 1:
            return r[0]
        return r
    def subst(self):
        self.vars = {k:self.subst_var(k, v) for k,v in self.items()}
    def copy(self, **kwargs):
        builders = dict(_builders = self.builders) if hasattr(self, 'builders') else {}
        new_env = Environment(**builders,**self.vars,**kwargs)
        for b in new_env.builders.values():
            b.set_env(new_env)
        return new_env
    def addBuilder(self, **kwargs):
        for key, value in kwargs.items():
            self.builders[key] = value
            self.builders[key].write_rule(key)
    def __getattr__(self, key):
        if key != 'builders' and key in self.builders:
            return self.builders[key]
        return self.__getattribute__(key)
    def __repr__(self):
        kwargs = dict(_builder=self.builders,**self.vars)
        args = [f'{k}={repr(v)}' for k,v in kwargs.items()]
        temp = ",".join(args)
        return f'Environment({temp})'
    def write(self):
        ninja_path = Path(self['build_dir'])/'build.ninja'
        self.writer.write(ninja_path)

class SingletonMeta(type):
    _instances = {}
    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            instance = super().__call__(*args, **kwargs)
            cls._instances[cls] = instance
        return cls._instances[cls]

class NinjaWriter(metaclass=SingletonMeta):
    def __init__(self):
        self.fd = io.StringIO()
        self.writer = ninja.Writer(self.fd)
        self.ninja_vars = ['in','out']
    def close(self):
        self.fd.close()
    def __getattr__(self, key):
        if key != 'writer':
            return getattr(self.writer,key)
        return self.__getattribute__(key)
    def filter_ninja_vars(self, var_list):
        return [i for i in var_list if not i in self.ninja_vars]
    def write(self,ninja_path):
        ninja_path.write_text(self.fd.getvalue())

class Builder:
    def __init__(self, command, depfile = None, get_env = None):
        self.command = command
        self.depfile = depfile
        self.writer = NinjaWriter()
        command_vars = MyTemplate(self.command).var_names
        self.env_vars = self.writer.filter_ninja_vars(command_vars)
        self.env = None
        self.name = None
        self.get_env = get_env
    def __repr__(self):
        kwargs = self.get_kwargs()
        args = [f'{k}={repr(v)}' for k,v in kwargs.items()]
        temp = ",".join(args)
        return f'Builder({temp})'
    def get_kwargs(self):
        kwargs = dict(command = self.command)
        if self.depfile is not None:
            kwargs['depfile'] = self.depfile
        return kwargs
    def set_env(self, env):
        self.env = env
    def write_rule(self, name):
        self.name = name
        rule_kwargs = self.get_kwargs()
        self.writer.rule(self.name, **rule_kwargs)
    def __call__(self, target, source):
        env = self.env
        if callable(self.get_env):
            env = self.get_env(self.env.copy())
        for k in self.env_vars:
            self.writer.variable(k,env[k])
        if isinstance(source, str):
            source = [source]
        source = [Path(src) for src in source]
        if callable(target):
            target = [target(src) for src in source]
        translated_target = [env.translate_path(tgt) for tgt in target]
        for src,tgt in zip(source,translated_target):
            src = str(src)
            tgt = str(tgt)
            self.writer.build(tgt,self.name,src)
        return translated_target
