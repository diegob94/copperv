#!/usr/bin/env python3

import sys
from pathlib import Path
import os

def tests_paths(root):
    return [
        root/'sim/tests', 
        root/'util/riscv-tests/isa/rv32ui',
    ]

def get_all_tests(root):
    r = []
    for p in tests_paths(root):
        for t in sorted(list(p.glob('*.S'))+list(p.glob('*.c'))):
            r.append(dict(
                test = t.stem,
                source = t,
            ))
    return r

def get_deps(sources,sdk):
    for source in sources:
        if source.suffix == '.c':
            sources.append(Path(f'{sdk}/crt0.S'))
            break
    r = []
    for s in ['.D','.E','.o']:
        for source in sources:
            r.append(source.with_suffix(s))
    print(' '.join([str(i) for i in r]))

if __name__=='__main__':
    root = Path('../')
    if len(sys.argv) - 1 != 2:
        sys.exit(0)
    test = sys.argv[1]
    sdk = sys.argv[2]
    for t in get_all_tests(root):
        if t['test'] == test:
            get_deps([t['source']],sdk)
            break


