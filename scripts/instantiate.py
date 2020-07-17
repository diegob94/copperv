#!/usr/bin/env python3
from pathlib import Path
import re
import sys
import argparse

def parse(module, tokens):
    r = dict(module = module)
    for i,t in enumerate(tokens):
        t = t.strip()
        if i == 0:
            r['direction'] = t
        elif t in ['reg']:
            r['type'] = t
        elif t.startswith('[') and t.endswith(']'):
            r['width'] = t
        else:
            r['name'] = t
    return r

def write_instatiation(parsed):
    print(f'{parsed[0]["module"]} dut (')
    for i,port in enumerate(parsed):
        comma = ',' if i != len(parsed)-1 else ''
        print(f'    .{port["name"]}({port["name"]}){comma}')
    print(');')

def write_tb_signals(parsed):
    def write(parsed, direction, _type):
        for port in parsed:
            if port['direction'] == direction:
                width = port['width'] + ' ' if 'width' in port else ''
                print(f'{_type} {width}{port["name"]};')
    print(f'// {parsed[0]["module"]} inputs')
    write(parsed, 'input', 'reg')
    print(f'// {parsed[0]["module"]} outputs')
    write(parsed, 'output', 'wire')

parser = argparse.ArgumentParser(description='Write Verilog instatiation code')
parser.add_argument('source', type=Path, help='Source Verilog file')
parser.add_argument('module', help='Module name')
parser.add_argument('-tb', action = 'store_true', help='Include testbench signals')
parser.add_argument('-debug', action = 'store_true', help='Debug mode')
args = parser.parse_args()

regex = re.compile(f'module\s+{args.module}')
in_declaration = False
declaration = ''
with args.source.open('r') as f:
    for line in f:
        if regex.search(line):
            in_declaration = True
        if in_declaration:
            declaration += line.strip()
        if ');' in line:
            break
if args.debug:
    print('DEBUG: declaration:')
    print(declaration)
ports = regex.sub('',declaration).strip()
if args.debug:
    print('DEBUG: ports1:')
    print(ports)
ports_t = ports
ports = ''
b = 0
done = False
for c in ports_t.lstrip('#'):
    if done:
        ports += c
    if c == '(':
        b += 1
    elif c == ')':
        b -= 1
    if b == 0:
        done = True
if args.debug:
    print('DEBUG: ports2:')
    print(ports)
ports = ports.strip().lstrip('(').rstrip(';').rstrip(')')
if args.debug:
    print('DEBUG: ports3:')
    print(ports)
ports = ports.split(',')
if args.debug:
    print('DEBUG: ports:')
    print(ports)
parsed = [parse(args.module, i.split()) for i in ports]
if args.debug:
    print("DEBUG:")
    print('\n'.join([repr(i) for i in parsed]))

if args.tb:
    write_tb_signals(parsed)
write_instatiation(parsed)
