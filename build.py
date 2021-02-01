#!/usr/bin/env python
import sys
import logging
import argparse

from scripts.copperv_tools import buildtool, tests

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

#test = tests['simple']
test = tests['rv32ui']
test_dir = 'test_' + test.name
test_objs = []
for test_source in test.source:
    test_objs.append(buildtool.test_object(
        target = lambda target_dir, input_file: target_dir/test_dir/input_file.with_suffix('.o').name,
        source = test_source,
        inc_dir = test.inc_dir,
    ))
    buildtool.test_preprocess(
        target = lambda target_dir, input_file: target_dir/test_dir/input_file.with_suffix('.E').name,
        source = test_source,
        inc_dir = test.inc_dir,
    )
test_elf = buildtool.test_link(
    target = lambda target_dir: target_dir/test_dir/f'{test.name}.elf',
    source = test_objs,
)
test_hex = buildtool.test_verilog_hex(
    target = lambda target_dir: target_dir/test_dir/f'{test.name}.hex',
    source = test_elf,
)
test_diss = buildtool.test_dissassemble(
    target = lambda target_dir: target_dir/test_dir/f'{test.name}.D',
    source = test_elf,
)

rtl_inc_dir = buildtool.root/'rtl/include'
rtl_headers = list(rtl_inc_dir.glob('*.v'))
rtl_sources = list((buildtool.root/'rtl').glob('*.v'))

sim_inc_dir = buildtool.root/'sim/include'
sim_headers = list(sim_inc_dir.glob('*.v'))
sim_sources = list((buildtool.root/'sim').glob('*.v'))
sim_sources.extend(list((buildtool.root/'sim').glob('*.sv')))
sim_sources = [f for f in sim_sources if f.name != 'checker_cpu.v']

sim_dir = 'sim'
log_dir = 'log'

tools_vpi = buildtool.vpi(
    target = lambda target_dir: target_dir/sim_dir/'copperv_tools.vpi',
    source = buildtool.root/'sim/copperv_tools.c',
    cwd = lambda target_dir: target_dir/sim_dir,
    implicit_target = lambda target_dir: target_dir/sim_dir/'copperv_tools.o',
)
vvp = buildtool.sim_compile(
    target = lambda target_dir: target_dir/sim_dir/'sim.vvp',
    source = rtl_sources + sim_sources,
    log = lambda target_dir: target_dir/log_dir/'sim_compile.log',
    cwd = lambda target_dir: target_dir/sim_dir,
    header_files = rtl_headers + sim_headers,
    tools_vpi = tools_vpi,
    inc_dir = [rtl_inc_dir, sim_inc_dir],
)
sim_run = buildtool.sim_run(
    target = buildtool.LOG_FILE,
    source = vvp,
    log = lambda target_dir: target_dir/log_dir/f'sim_run_{test.name}.log',
    cwd = lambda target_dir: target_dir/sim_dir,
    hex_file = test_hex,
    diss_file = test_diss,
    implicit_target = lambda target_dir: [target_dir/sim_dir/name for name in ['fake_uart.log','tb.vcd']]
)
buildtool.check_sim(
    target = 'all',
    source = sim_run,
)

buildtool.run()
