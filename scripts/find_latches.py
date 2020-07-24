#!/usr/bin/env python3
import sys
import argparse

from pyyosys import DesignTree

parser = argparse.ArgumentParser(description='Find latches in a sythesized netlist.')
parser.add_argument('netlist_json', type=str, help='Netlist in JSON format')
args = parser.parse_args()

def _find_latches(leaf):
    return leaf.attributes['src'] if 'DLATCH' in leaf.module_name else None

design = DesignTree(args.netlist_json)
latches = design.map_tree_leafs(_find_latches)

if len(latches)>1:
    print('Warning: Latches found in design, RTL tracing:')
    print('  ' + '\n  '.join(set(latches)))
    sys.exit(1)
else:
    print('Info: no latches found in design')
    sys.exit(0)
