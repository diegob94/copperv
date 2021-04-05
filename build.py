#!/usr/bin/env python
import sys
import logging
import argparse
import os

# unbuffered output
class Unbuffered:
   def __init__(self, stream):
       self.stream = stream
   def write(self, data):
       self.stream.write(data)
       self.stream.flush()
   def writelines(self, datas):
       self.stream.writelines(datas)
       self.stream.flush()
   def __getattr__(self, attr):
       return getattr(self.stream, attr)

sys.stdout = Unbuffered(sys.stdout)

from scripts.copperv_tools import buildtool, tests

parser = argparse.ArgumentParser(description='Build Copperv core')
parser.add_argument('-d','--debug',dest='debug',action='store_true',
        help='Enable debug output')
parser.add_argument('-t','--test',dest='test',default='simple',
        help=f'CPU test to run. Defaults to rv32ui test suite, available tests: {", ".join(tests.keys())}')
parser.add_argument('--ninja_opts',default=None,help=f'Options for ninja')
parser.add_argument('--gtkwave',dest='gtkwave',action='store_true',
        help='Open VCD in gtkwave')

args = parser.parse_args()

level=logging.WARNING
if args.debug:
    level=logging.DEBUG

logging.basicConfig(
    stream=sys.stdout,
    format="[%(filename)s:%(lineno)s %(funcName)s()] %(message)s",
    level=level,
)

test = tests[args.test]
test_dir = 'test_' + test.name
test_objs = []
for test_source in test.source:
    cflags = " ".join([f'-I{i}' for i in test.inc_dir])
    if test.cflags is not None:
        cflags += ' ' + test.cflags
    test_objs.append(buildtool.test_object(
        target = f'$target_dir/{test_dir}/{test_source.stem}.o',
        source = test_source,
        cflags = cflags,
    ))
    buildtool.test_preprocess(
        target = f'$target_dir/{test_dir}/{test_source.stem}.E',
        source = test_source,
        cflags = cflags,
    )
    buildtool.test_dissassemble(
        target = f"$target_dir/{test_dir}/{test_source.stem}_obj.D",
        source = test_objs[-1],
    )
test_elf = buildtool.test_link(
    target = f'$target_dir/{test_dir}/{test.name}.elf',
    source = test_objs,
    implicit_source = '$linkerscript',
)
test_hex = buildtool.test_verilog_hex(
    target = f'$target_dir/{test_dir}/{test.name}.hex',
    source = test_elf,
)
test_diss = buildtool.test_dissassemble(
    target = f'$target_dir/{test_dir}/{test.name}.D',
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

inc_dir = [rtl_inc_dir, sim_inc_dir]
iverilogflags = " ".join([f'-I{i}' for i in inc_dir])

sim_dir = 'sim'
log_dir = 'log'

tools_vpi,implicit = buildtool.vpi(
    target = f'$target_dir/{sim_dir}/copperv_tools.vpi',
    source = buildtool.root/'sim/copperv_tools.c',
    cwd = f'$target_dir/{sim_dir}',
    implicit_target = f'$target_dir/{sim_dir}/copperv_tools.o',
)
vvp, sim_compile_log = buildtool.sim_compile(
    target = f'$target_dir/{sim_dir}/sim.vvp',
    source = rtl_sources + sim_sources,
    log = f'$target_dir/{log_dir}/sim_compile.log',
    cwd = f'$target_dir/{sim_dir}',
    implicit_source = rtl_headers + sim_headers + [tools_vpi],
    iverilogflags = iverilogflags,
)
sim_run_log, fake_uart, vcd_file = buildtool.sim_run(
    target = f'$target_dir/{log_dir}/sim_run_{test.name}.log',
    implicit_target = [
        f'$target_dir/{sim_dir}/fake_uart.log',
        f'$target_dir/{sim_dir}/tb.vcd',
    ],
    source = vvp,
    cwd = f'$target_dir/{sim_dir}',
    hex_file = test_hex,
    diss_file = test_diss,
    implicit_source = ['$hex_file', '$diss_file'],
)

if test.show_stdout:
    buildtool.show_stdout(
        target = 'show_stdout',
        source = fake_uart,
    )

if args.gtkwave:
    buildtool.gtkwave(
        target = 'gtkwave',
        source = vcd_file,
        cwd = f'$target_dir/{sim_dir}',
    )

buildtool.run(
    ninja_opts = args.ninja_opts,
)

