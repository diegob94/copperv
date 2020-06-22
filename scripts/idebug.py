#!/usr/bin/env python
from pathlib import Path
import re
import cmd
import sys
from functools import wraps

class DebugShell(cmd.Cmd):
    intro = 'Welcome to the debug shell.\n- Type help or ? to list commands.\n'
    prompt = '(debug) '
    def parse_args(method):
        @wraps(method)
        def wrapper(self,args):
            self.out.debug('parse_args:',repr(args))
            args = args.split()
            return method(self,*args)
        return wrapper
    def __init__(self, config):
        super().__init__()
        self.config = config
        self.tracer = Tracer(config)
        self.out = ShellOutput(config)
    def do_next(self, arg):
        'Go to next line'
        r = self.tracer.next_line()
        self.out.print_trace(**r)
    @parse_args
    def do_set_config(self, name = None, value = None):
        'Set options'
        if name is None or value is None:
            self.out.error('Missing arguments\n    set_config <name> <value>')
            return False
        self.config[name] = value
        self.out._return(self.tracer.config[name])
    @parse_args
    def do_get_config(self, name = None):
        'Get options'
        if name is None:
            self.out.error('Missing arguments\n    set_config <name> <value>')
            return False
        value = self.config[name]
        self.out._return(value)
    def do_quit(self, arg):
        'Quit shell'
        print('Closing shell\n')
        self.tracer.close()
        return True

class ShellOutput:
    def __init__(self, config):
        self.config = config
    def error(self, msg):
        print('Error:', msg)
    def debug(self, *args, **kwargs):
        if self.config.debug:
            print('DEBUG:', *args, **kwargs)
    def print_trace(self, log, rtl, stdout = None):
        def print_before_after(rtl,ba):
            for i,line in zip(rtl[ba+'_number'],rtl[ba]):
                print(f'   {i:>6}:', line.rstrip(' '))
        self.debug(rtl)
        print('Sim log:', log)
        print_before_after(rtl,'before')
        i = rtl['line_number']
        print(f' ->{i:>6}:', rtl['line'].rstrip(' '))
        print_before_after(rtl,'after')
        if stdout is not None:
            print('Sim stdout:')
            for line in stdout:
                print(line.rstrip(' '))
    def _return(self, r):
        print(r)

class GenericConfig:
    def __init__(self, initval):
        self.value = initval
    def __get__(self, obj, objtype):
        return self.value
    def __set__(self, obj, value):
        self.value = value

class ListConfig(GenericConfig):
    def __get__(self, obj, objtype):
        return tuple(self.value)
    def __set__(self, obj, value):
        self.value.append(value)

class BoolConfig(GenericConfig):
    def __set__(self, obj, value):
        if value.lower() == 'true':
            self.value = True
        else:
            self.value = False

class Config:
    def __init__(self):
        config = {
            'log':    GenericConfig(None),
            'before': GenericConfig(5),
            'after':  GenericConfig(5),
            'debug':  BoolConfig(False),
            'filter': ListConfig([]),
            'break':  ListConfig([]),
        }
        for k,v in config.items():
            setattr(Config, k, v)
    def __getitem__(self, key):
        return getattr(self, key)
    def __setitem__(self, key, value):
        return setattr(self, key, value)

class Tracer:
    def __init__(self, config):
        self.log_fp = config.log.open('r')
        self.regex = re.compile('^([\w./]+):(\d+): (.*?)')
        self.rtl_cache = dict()
        self.config = config 
    def close(self):
        self.log_fp.close()
    def readline(self):
        return self.log_fp.readline().strip('\n')
    def next_line(self):
        r = dict()
        line = self.readline()
        for f in self.config.filter:
            if f in line:
                #print('DEBUG: filter', self.config.filter, line)
                return self.next_line()
        r['log'] = line
        r['rtl'] = self.parse(line)
        if r['rtl'] is None:
            return self.next_line()
        while True:
            last_pos = self.log_fp.tell()
            line = self.readline()
            rtl = self.parse(line)
            if rtl is None:
                if not 'stdout' in r:
                    r['stdout'] = []
                r['stdout'].append(line)
            else:
                self.log_fp.seek(last_pos)
                break
        #print('DEBUG: return', r)
        return r
    def parse(self, line):
        m = self.regex.search(line)
        rtl = None
        if m:
            source = m[1]
            n = m[2]
            rtl = self.get_rtl(source, n)
        return rtl
    def read_rtl(self, path):
        if not path in self.rtl_cache:
            self.rtl_cache[path] = Path(path).read_text().splitlines()
        return self.rtl_cache[path]
    def get_rtl(self, path, n):
        rtl = self.read_rtl(path)
        i = int(n) - 1
        r = dict(line_number = int(n))
        low = max(0, i - self.config.before)
        high = min(len(rtl), i + 1 + self.config.after)
        r['before'] = rtl[low:i]
        r['line'] = rtl[i]
        r['after'] = rtl[i+1:high]
        r['before_number'] = list(range(low+1,i+1))
        r['after_number'] = list(range(i+2,high+1))
        return r

config = Config()
config.log = Path('sim_run.log')
DebugShell(config).cmdloop()

