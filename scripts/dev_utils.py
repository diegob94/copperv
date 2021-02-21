#!/usr/bin/env python3
from pathlib import Path
import re
import argparse
import sys
from datetime import datetime
import os
import subprocess as sp

from tabulate import tabulate

script_name = Path(sys.argv[0]).name

class Run:
    def __init__(self,caller):
        self.caller = caller
    def __call__(self,cmd):
        print(f'{self.caller}:',cmd)
        return sp.run(cmd,capture_output=True,encoding="utf-8",shell=True,check=True).stdout

def generated(file):
    print(f"Generated: {file.resolve()}")

def generate_dissassembly_file(diss,elf_file,objdump):
    diss = Path(diss)
    def j_opt(sections):
        return ' '.join([f'-j {s}' for s in sections])
    inst_sections = ['.init', '.text']
    run = Run('generate_dissassembly_file')
    r = run(f'{objdump} -S -Mno-aliases -r {elf_file} {j_opt(inst_sections)}')
    all_sections = run(f'{objdump} -h {elf_file}').splitlines()
    start = next((i for i,line in enumerate(all_sections) if line.startswith('Sections:')),None)
    all_sections = [line.split()[1] for line in all_sections[start:] if re.search('^\s+\d',line)]
    non_inst_sections = [i for i in all_sections if not i in inst_sections]
    r += run(f'{objdump} -s {elf_file} {j_opt(non_inst_sections)}')
    diss.write_text(r)
    generated(diss)
    return diss

def get_printer(name, width, entries):
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

def generate_monitor_code(header):
    header = Path(header)
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
    printer_header  = [f'// File generated by {script_name} script ({datetime.now().astimezone().isoformat()})']
    for parse in parse_this:
        printer_header.append(get_printer(parse['name'],parse['width'],parse['entries']))
    monitor_code = dict(
        printers = printer_header,
        gtkwave = {parse['name']:parse['gtkwave'] for parse in parse_this}
    )
    return monitor_code

def generate_monitor_printer(monitor,rtl_header):
    monitor = Path(monitor)
    monitor_code = generate_monitor_code(rtl_header)
    monitor.write_text('\n\n'.join(monitor_code['printers']) + '\n')
    generated(monitor)
    return monitor

def generate_gtkwave_filters(gtkwave_dir,rtl_header):
    gtkwave_dir = Path(gtkwave_dir)
    monitor_code = generate_monitor_code(rtl_header)
    out_files = []
    for name,gtkwave_filter in monitor_code['gtkwave'].items():
        path = (gtkwave_dir/name).with_suffix('.gtkwfilter')
        path.write_text('\n'.join(gtkwave_filter) + '\n')
        generated(path)
        out_files.append(path)
    return out_files

def parse_verilog_hex(v_hex_file):
    data = {}
    addr = 0
    for token in re.split('\s+',v_hex_file.read_text().strip()):
        if token.startswith('@'):
            addr = int(token.lstrip('@'),16)
            continue
        data[addr] = int(token,16)
        addr += 1
    return data

class VerilogHexWriter:
    def __init__(self, out_path, addr_width = 0, data_width = 0, columns = 4):
        self.out_path = out_path
        self.lines = []
        self.addr_width = addr_width
        self.data_width = data_width
        self.columns = columns
        self.buffer = []
    @staticmethod
    def hex(value, width = 0):
        return f'{value:0{width}X}'
    def address(self, addr):
        self.flush_columns()
        self.lines.append('@'+self.hex(addr, self.addr_width))
    def value(self, value):
        self.buffer.append(self.hex(value, self.data_width))
        if len(self.buffer) == self.columns:
            self.flush_columns()
    def flush_columns(self):
        if len(self.buffer) != 0:
            self.lines.append(' '.join(self.buffer))
            self.buffer = []
    def write(self):
        self.out_path.write_text('\n'.join(self.lines)+'\n')

class Memory:
    def __init__(self, v_hex_file):
        self.v_hex_file = v_hex_file
        self.data = parse_verilog_hex(self.v_hex_file)
    def get_max_width(self):
        max_addr_width = max([len(VerilogHexWriter.hex(i)) for i in self.data.keys()])
        max_data_width = max([len(VerilogHexWriter.hex(i)) for i in self.data.values()])
        return max_addr_width, max_data_width
    def __str__(self):
        return tabulate(self.data.items(),headers=['address','value'])
    def insert(self, start_address, data):
        for i,value in enumerate(data):
            addr = start_address + i
            self.data[addr] = value
    def write_verilog_hex(self, out_path):
        writer = VerilogHexWriter(out_path, *self.get_max_width())
        address = sorted(self.data.keys())
        last_addr = 0
        for addr in address:
            if addr != last_addr + 1:
                writer.address(addr)
            writer.value(self.data[addr])
            last_addr = addr
        writer.address(addr+1)
        writer.write()


readelf_regex = re.compile(r'\[\s*(\d+)]\s+(\.[\w.]+)?\s+(\w+)\s+([\da-f]+)\s+([\da-f]+)\s+([\da-f]+)\s+(\d+)\s+([A-Z]+)?\s+(\d+)\s+(\d+)\s+(\d+)')

def parse_readelf(text):
    table = []
    for line in text.splitlines():
        m = readelf_regex.search(line)
        if m:
            table.append(m.groups())
    return table

def generate_hex_file(hex_file: Path,elf_file: Path,objcopy,readelf,v_hex_file):
    run = Run('generate_hex_file')
    if elf_file is not None:
        v_hex_file = hex_file.with_suffix('.ocpy_v_hex')
        run(f'{objcopy} -O verilog {elf_file} {v_hex_file}')
        readelf_output = run(f'{readelf} -S {elf_file}')
        section_table = parse_readelf(readelf_output)
        init_zeros = [{'name':line[1],'addr':int(line[3],16),'size':int(line[5],16)} for line in section_table if 'NOBITS' in line]
    else:
        init_zeros = []
    mem = Memory(v_hex_file)
    print("\nZero initialized sections:")
    print(tabulate([{k:v if k != 'addr' else hex(v) for k,v in row.items()} for row in init_zeros],headers="keys"))
    print()
    debug_hex_file = hex_file.with_suffix('.debug_hex')
    mem.write_verilog_hex(debug_hex_file)
    generated(debug_hex_file)
    for row in init_zeros:
        mem.insert(row['addr'],[0]*row['size'])
    mem.write_verilog_hex(hex_file)
    generated(hex_file)


if __name__=='__main__':
    header_params = dict(
        metavar='RTL_HEADER_PATH',
        type=Path,
        help='RTL header file input for monitor and gtkwave filter',
    )
    elf_params = dict(
        metavar='ELF_PATH',
        type=Path,
        help='ELF file to dissassemble input',
    )
    out_params = dict(
        metavar='OUT_PATH',
        type=Path,
        help='Output path',
        required=True,
    )
    parser = argparse.ArgumentParser(description='Generate testbench')
    subparsers = parser.add_subparsers()
    # Monitor header
    parser_mon = subparsers.add_parser('monitor_header')
    parser_mon.add_argument('rtl_header',**header_params)
    parser_mon.add_argument('-o',**out_params,dest='monitor')
    parser_mon.set_defaults(func=generate_monitor_printer)
    # GTKWave filters
    parser_gtkwf = subparsers.add_parser('gtkwave_filters')
    parser_gtkwf.add_argument('rtl_header',**header_params)
    parser_gtkwf.add_argument('-o',**out_params,dest='gtkwave')
    parser_gtkwf.set_defaults(func=generate_gtkwave_filters)
    # Dissassembly
    parser_diss = subparsers.add_parser('dissassemble')
    parser_diss.add_argument('elf_file',**elf_params)
    parser_diss.add_argument('-o',**out_params,dest='diss')
    parser_diss.add_argument('-objdump',metavar='OBJDUMP_PATH',type=Path,help='Path to objdump (required)',required=True)
    parser_diss.set_defaults(func=generate_dissassembly_file)
    # Hex file
    parser_hex = subparsers.add_parser('hex')
    in_group = parser_hex.add_mutually_exclusive_group(required=True)
    in_group.add_argument('-elf_file',**elf_params)
    in_group.add_argument('-v_hex_file',metavar='V_HEX_FILE',type=Path,help='Verilog hex file',dest='v_hex_file')
    parser_hex.add_argument('-o',**out_params,dest='hex_file')
    parser_hex.add_argument('-objcopy',metavar='OBJCOPY_PATH',type=Path,help='Path to objcopy (required)',required=True)
    parser_hex.add_argument('-readelf',metavar='READELF_PATH',type=Path,help='Path to readelf (required)',required=True)
    parser_hex.set_defaults(func=generate_hex_file)
    ## do work
    args = parser.parse_args()
    if len(vars(args)) == 0:
        parser.print_usage()
        sys.exit(1)
    args_dict = dict(vars(args))
    args_dict.pop('func')
    args.func(**args_dict)

