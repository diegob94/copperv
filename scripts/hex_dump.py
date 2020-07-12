#!/usr/bin/env python
import pandas as pd
import numpy as np
from pathlib import Path
import re
import argparse

def decode(word):
    word_bin = np.binary_repr(word,32)
    opcode = word_bin[-7:]
    return dict(opcode = opcode)

parser = argparse.ArgumentParser(description='Dump Verilog hex file words')
parser.add_argument('hex_file', type=Path, help='Input hex file')
parser.add_argument('-o', type=Path, dest='out_file', default=None, help='Output dump file')
args = parser.parse_args()

hex_file = args.hex_file
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
        if i + j > len(data) - 1:
            break
        value = f"{int(data[i+j]['byte'],16):X}" + value
    for j in range(4):
        if i + j > len(data) - 1:
            break
        if j == 0:
            word = int(value, 16)
            decoded = decode(word)
            word_hex = f'0x{word:08X}'
            data[i+j].update(decoded)
        else:
            word_hex = ''
        data[i+j].update(dict(word = word_hex))

df = pd.DataFrame(data)
df.address = df.address.apply(lambda x: f'0x{x:08X}')

if args.out_file is None:
    out_file = hex_file.with_suffix('.hex_dump')
elif str(args.out_file) == '-':
    out_file = Path('/dev/stdout')
else:
    out_file = args.out_file
out_file.write_text(df.query("word.str.len() > 0").drop(columns = "byte").to_string(index=False) + '\n')

