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
            args = args.split()
            return method(self,*args)
        return wrapper
    def __init__(self, tracer):
        super().__init__()
        self.tracer = tracer
        self.out = ShellOutput()
    def do_next(self, arg):
        'Go to next line'
        r = tracer.next_line()
        self.out.print_trace(**r)
    @parse_args
    def do_set_config(self, name = None, value = None):
        'Set options'
        if name is None or value is None:
            self.out.error('Missing arguments\n    set_config <name> <value>')
            return False
        self.tracer.config[name].value = value
        self.out._return(self.tracer.config[name].value)
    @parse_args
    def do_get_config(self, name = None):
        'Get options'
        if name is None:
            self.out.error('Missing arguments\n    set_config <name> <value>')
            return False
        value = self.tracer.config[name].value
        self.out._return(value)
    def do_quit(self, arg):
        'Quit shell'
        print('Closing shell\n')
        self.tracer.close()
        return True

class ShellOutput:
    def __init__(self):
        pass
    def error(self, msg):
        print('Error:', msg)
    def print_trace(self, log, rtl, stdout = None):
        print('Sim log:', log)
        for line in rtl:
            print('Rtl ->', line.strip(' '))
        if stdout is not None:
            print('Sim stdout:')
            for line in stdout:
                print(line.strip(' '))
    def _return(self, r):
        print(r)

class Config:
    def __init__(self, initial_value):
        self.cast = type(initial_value)
        self._value = initial_value
    @property
    def value(self):
        return self._value
    @value.setter
    def value(self, value):
        self._value = self.cast(value)

class Tracer:
    def __init__(self, log_path):
        self.log_fp = Path(log_path).open('r')
        self.regex = re.compile('^([\w./]+):(\d+): (.*?)')
        self.rtl_cache = dict()
        self.config = dict(before = Config(0), after = Config(0))
    def close(self):
        self.log_fp.close()
    def readline(self):
        return self.log_fp.readline().strip('\n')
    def next_line(self):
        r = dict()
        line = self.readline()
        r['log'] = line
        r['rtl'] = self.parse(line)
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
        return r
    def parse(self, line):
        m = self.regex.search(line)
        sline = None
        if m:
            source = m[1]
            n = m[2]
            sline = [i.strip('\n') for i in self.get_line(source, n)]
        return sline
    def read_rtl(self, path):
        if not path in self.rtl_cache:
            self.rtl_cache[path] = Path(path).read_text().splitlines()
        return self.rtl_cache[path]
    def get_line(self, path, n):
        rtl = self.read_rtl(path)
        low = max(0, int(n) - 1 - self.config['before'].value)
        high = min(len(rtl), low + 1 + self.config['after'].value)
        r = rtl[low:high]
        return r

tracer = Tracer('sim_run.log')
DebugShell(tracer).cmdloop()

