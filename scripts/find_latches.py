#!/usr/bin/env python3
from pyyosys import DesignTree
import argparse

parser = argparse.ArgumentParser(description='Find latches in a sythesized netlist.')
parser.add_argument('netlist_json', type=str, help='Netlist in JSON format')
args = parser.parse_args()

def _find_latches(leaf):
    return leaf.attributes['src'] if 'DLATCH' in leaf.module_name else None

design = DesignTree(args.netlist_json)
latches = design.map_tree_leafs(_find_latches)

print('Latches:')
print('\n'.join(set(latches)))
