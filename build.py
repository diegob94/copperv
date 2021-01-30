#!/usr/bin/env python
import sys
import logging
import argparse

from scripts.copperv_tools import build, tests


parser = argparse.ArgumentParser(description='Build Copperv core')
parser.add_argument('-d','--debug',dest='debug',action='store_true',
        help='Enable debug output')

args = parser.parse_args()

level=logging.WARNING
if args.debug:
    level=logging.DEBUG

logging.basicConfig(
    stream=sys.stdout,
    format="[%(filename)s:%(lineno)s %(funcName)s()] %(message)s",
    level=level,
)
def which_lambda(value):
    import inspect
    code,line = inspect.getsourcelines(value)
    file = inspect.getsourcefile(value)
    code = ' '.join([repr(i) for i in code])
    print(f"{file}:{line} {code}")
import builtins
builtins.which_lambda = which_lambda

test = tests['simple']
test_dir = 'test_' + test.name
test_objs = []
for test_source in test.source:
    test_objs.append(build.test_object(
        target = lambda target_dir, input_file: target_dir/test_dir/input_file.with_suffix('.o').name,
        source = test_source,
        inc_dir = test.inc_dir,
    ))
    build.test_preprocess(
        target = lambda target_dir, input_file: target_dir/test_dir/input_file.with_suffix('.E').name,
        source = test_source,
        inc_dir = test.inc_dir,
    )
test_elf = build.test_link(
    target = lambda target_dir, _: target_dir/test_dir/f'{test.name}.elf',
    source = test_objs,
)
test_hex = build.test_verilog_hex(
    target = lambda target_dir, _: target_dir/test_dir/f'{test.name}.hex',
    source = test_elf,
)
test_diss = build.test_dissassemble(
    target = lambda target_dir, _: target_dir/test_dir/f'{test.name}.D',
    source = test_elf,
)
sim_dir = 'sim'
build.sim_run(
    target = 'sim_run',
    source = 'sim.vvp',
    wd = lambda target_dir: target_dir/sim_dir,
    hex_file = test_hex,
    diss_file = test_diss,
    logs_dir = 'log',
    test_name = test.name,
)

build.run()
