#!/usr/bin/env python3
import sys
import argparse

from pyosys import DesignTree

parser = argparse.ArgumentParser(description='Find latches in a sythesized netlist.')
parser.add_argument('netlist_json', type=str, help='Netlist in JSON format')
args = parser.parse_args()

def _find_latches(leaf):
    return leaf.attributes['src'] if 'DLATCH' in leaf.module_name else None

def _find_ff(leaf):
    return leaf if 'DFF' in leaf.module_name else None

design = DesignTree(args.netlist_json)
latches = design.map_tree(_find_latches, 'leaf')

if len(latches)>1:
    print('Warning: Latches found in design, RTL tracing:')
    print('  ' + '\n  '.join(set(latches)))
    sys.exit(1)
else:
    print('Info: no latches found in design')
    sys.exit(0)

