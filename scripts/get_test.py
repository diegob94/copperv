#!/usr/bin/env python

import sys
from pathlib import Path

def tests_paths(root):
    return [
        root/'sim/tests', 
        root/'util/riscv-tests/isa/rv32ui',
    ]

def get_all_tests(root):
    r = []
    for p in tests_paths(root):
        for t in sorted(p.glob('*.S')):
            r.append(dict(
                test = t.stem,
                source = t,
            ))
    return r

if __name__=='__main__':
    root = Path('../')
    test = sys.argv[1]
    for t in get_all_tests(root):
        if t['test'] == test:
            print(t['source'])
            break


