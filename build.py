#!/usr/bin/env python
import sys
import logging
import argparse

from scripts.copperv_tools import buildtool, tests

parser = argparse.ArgumentParser(description='Build Copperv core')
parser.add_argument('-d','--debug',dest='debug',action='store_true',
        help='Enable debug output')
parser.add_argument('-t','--test',dest='test',default='rv32ui',
        help=f'CPU test to run. Defaults to rv32ui test suite, available tests: {", ".join(tests.keys())}')
parser.add_argument('target',nargs='?',default=None,
        help=f'Target to build')

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

test = tests[args.test]
test_dir = 'test_' + test.name
test_objs = []
for test_source in test.source:
    test_objs.append(buildtool.test_object(
        target = lambda target_dir: target_dir/test_dir/test_source.with_suffix('.o').name,
        source = test_source,
        inc_dir = test.inc_dir,
    ))
    buildtool.test_preprocess(
        target = lambda target_dir: target_dir/test_dir/test_source.with_suffix('.E').name,
        source = test_source,
        inc_dir = test.inc_dir,
    )
    buildtool.test_dissassemble(
        target = lambda target_dir: target_dir/test_dir/('obj_'+test_source.with_suffix('.D').name),
        source = test_objs[-1],
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
sim_run_log, fake_uart, vcd_file = buildtool.sim_run(
    target = [
        buildtool.LOG_FILE,
        lambda target_dir: target_dir/sim_dir/'fake_uart.log',
        lambda target_dir: target_dir/sim_dir/'tb.vcd',
    ],
    source = vvp,
    log = lambda target_dir: target_dir/log_dir/f'sim_run_{test.name}.log',
    cwd = lambda target_dir: target_dir/sim_dir,
    hex_file = test_hex,
    diss_file = test_diss,
)
buildtool.check_sim(
    target = 'check_sim',
    source = sim_run_log,
)
default_target = ['check_sim']

if test.show_stdout:
    buildtool.show_stdout(
        target = 'show_stdout',
        source = fake_uart,
    )
    default_target.append('show_stdout')

buildtool.gtkwave(
    target = 'gtkwave',
    source = vcd_file,
    cwd = lambda target_dir: target_dir/sim_dir,
)

buildtool.run(
    default_target = default_target,
    target = args.target
)

