from pathlib import Path
import re

opcodes = Path('../util/riscv-opcodes/opcodes-rv32i')
table = []
with opcodes.open('r') as f:
    for line in f:
        if line.strip().startswith('#') or line.strip() == '':
            continue
        row = {}
        token = re.split('\s+', line.strip())
        row['name'] = token[0]
        code = 0
        for t in token[1:]:
            if '..' in t:
                r,v = t.split('=')
                r1,r2 = r.split('..')
                code |= int(v,0) << int(r2)
                print(t,r1,r2,int(v,0))
        row['code'] = f"{bin(code).lstrip('0b'):0>32s}"
        print(row)
