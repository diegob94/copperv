#!/usr/bin/env python
import pandas as pd
from pathlib import Path
import sys
import re

hex_file = Path(sys.argv[1])
tokens = []
with hex_file.open('r') as f:
    for line in f:
        tokens += re.split('\s+', line.strip())

data = []
address = 0
for token in tokens:
    if token.startswith('@'):
        address = int(token[1:], 16)
    else:
        data.append(dict(byte = f'0x{int(token, 16):02X}', address = address))
        address += 1

for i in range(0, len(data), 4):
    value = ''
    for j in range(4):
        value = f"{int(data[i+j]['byte'],16):X}" + value
    for j in range(4):
        if j == 0:
            new = f'0x{int(value, 16):08X}'
        else:
            new = ''
        data[i+j].update(dict(word = new))

df = pd.DataFrame(data)
print(df.to_string())
