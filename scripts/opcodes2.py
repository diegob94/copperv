from pathlib import Path
import re

opcodes = Path('../util/riscv-opcodes/opcodes-rv32i')
regex = re.compile('^(\w+).*?6..2=(\w+) 1..0=(\d+)')
opc = []
with opcodes.open('r') as f:
    for line in f:
        m = regex.search(line.strip())
        if m:
            opc.append(dict(name = m[1], code = (int(m[2], 0) << 2) | int(m[3], 0)))

for op in opc:
    print(op)
