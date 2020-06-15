#!/usr/bin/env python
from pathlib import Path
import re
import argparse
import sys
from datetime import datetime
from tabulate import tabulate

parser = argparse.ArgumentParser(description='Generate testbench')
parser.add_argument('header', type=Path, help='RTL header file')
parser.add_argument('dissassembly', type=Path, help='FW dissassembly file')
parser.add_argument('-monitor', type=Path, dest='monitor', help='Pretty print header file for monitor_cpu')
args = parser.parse_args()

def generate_printer(name, width, entries):
    printer_template = """
function `STRING {name};
input [`{width}-1:0] arg;
begin
    case (arg)
{entries_str}
        default:
            {name} = "UNKNOWN";
    endcase
end
endfunction
    """.rstrip().strip('\n')
    entry_template = """
        {entry}:
            {name} = "{entry_name}";
    """.rstrip().strip('\n')
    entries_str = []
    for entry in entries:
        entries_str.append(entry_template.format(
            entry = entry['entry'],
            name = name,
            entry_name = entry['entry_name']
        ))
    entries_str = '\n'.join(entries_str)
    return printer_template.format(
        name = name,
        width = width, 
        entries_str = entries_str
    )

def generate_dissassembly_printer(dis):
    inst = {}
    with dis.open('r') as f:
        for line in f:
            m=re.search('^\s+(\w+):\s+(\w+)\s+([\w.]+)\s+(.*)$',line)
            if m:
                inst["32'h"+m[1]] = [m[1]+':',m[2],m[3],m[4]]
    program = [v for v in inst.values()]
    table = tabulate(program,tablefmt='plain').split('\n')
    entries = [{'entry':k,'entry_name':v} for k,v in zip(inst.keys(),table)]
    printer_code = generate_printer('dissassembly','PC_WIDTH',entries)
    return printer_code

def generated(path):
    print(f"Generated {path.resolve()}")

def generate_monitor_code(header):
    parse_this = [
        dict(name = 'state'),
        dict(name = 'inst_type'),
        dict(name = 'funct'),
        dict(name = 'pc_next_sel'),
        dict(name = 'alu_op'),
    ]
    for parse in parse_this:
        parse['regex'] = re.compile(f'({parse["name"].upper()}_(\w+))\s+(\d+)')
        parse['entries'] = []
        parse['gtkwave'] = []
    with header.open('r') as f:
        for line in f:
            for parse in parse_this:
                m = parse['regex'].search(line)
                if m:
                    entry = m[1]
                    entry_name = m[2]
                    value = m[3]
                    if entry_name == 'WIDTH':
                        parse['width'] = entry
                    else:
                        f = dict(entry = '`'+entry, entry_name = entry_name)
                        parse['entries'].append(f)
                        parse['gtkwave'].append(f'{value} {entry_name}')
                    break
    printer_header = [f'// File generated by {Path(sys.argv[0]).name} {datetime.now()}']
    for parse in parse_this:
        printer_header.append(generate_printer(parse['name'],parse['width'],parse['entries']))
    monitor_code = dict(
        printers = printer_header,
        gtkwave = {parse['name']:parse['gtkwave'] for parse in parse_this}
    )
    return monitor_code

generated(args.monitor)
monitor_code = generate_monitor_code(args.header)
monitor_code['printers'].append(generate_dissassembly_printer(args.dissassembly))
args.monitor.write_text('\n\n'.join(monitor_code['printers']) + '\n')

for name,gtkwave in monitor_code['gtkwave'].items():
    path = (Path.cwd()/name).with_suffix('.gtkfilter')
    generated(path)
    path.write_text('\n'.join(gtkwave) + '\n')

