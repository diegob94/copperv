#!/usr/bin/env python3
import pexpect
import sys
import os
from pathlib import Path
import re

objdump = Path('riscv32-unknown-elf-objdump')

def run(cmd):
    print(cmd)
    return pexpect.run(cmd).decode("utf-8")

def j_opt(sections):
    return ' '.join([f'-j {s}' for s in sections])

inst_sections = ['.init', '.text']
obj = Path(sys.argv[1])

r = run(f'{objdump} -D -Mno-aliases {obj} {j_opt(inst_sections)}')

all_sections = run(f'{objdump} -h {obj}').splitlines()
start = next((i for i,line in enumerate(all_sections) if line.startswith('Sections:')),None)
all_sections = [line.split()[1] for line in all_sections[start:] if re.search('^\s+\d',line)]

non_inst_sections = [i for i in all_sections if not i in inst_sections]
r += run(f'{objdump} -s {obj} {j_opt(non_inst_sections)}')

out = obj.with_suffix('.D')
out.write_text(r)
print(f"Dissassembly: {out}")
