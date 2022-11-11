import pytest
from pathlib import Path
from cocotb_test.simulator import run
import os

import cocotb_utils as utils
import toml

root_dir = Path(__file__).resolve().parent.parent
sim_dir = root_dir/'sim'

def timescale_fix(verilog):
    verilog = Path(verilog)
    lines = verilog.read_text()
    if not any(['`timescale' in line for line in lines.splitlines()]):
        verilog.write_text("`timescale 1ns/1ps\n"+lines)
    return verilog

sources = toml.load(root_dir/'rtl/files.toml')
sources = {k:[root_dir/f for f in v] for k,v in sources.items()}
top_rtl = sources['TOP_RTL']
rtl_includes = sources['COPPERV_INCLUDES']

common_run_opts = dict(
    toplevel = "top",
    verilog_sources=top_rtl,
    includes=rtl_includes,
    module = "cocotb_tests",
    waves = True,
)

def test_top_skip_bootloader(request):
    test_name = 'hello_world'
    test_dir = sim_dir/f'tests/{test_name}'
    r = utils.run('make',cwd=test_dir)
    print(r)
    elf_path = test_dir/f'{test_name}.elf'
    hex_path = test_dir/f'{test_name}.hex'
    run(**common_run_opts,
        sim_build = sim_dir/request.node.name,
        testcase = "top_test",
        plus_args = [f"+HEX_FILE={hex_path}"],
        extra_env = {"ELF_PATH":elf_path}
    )

def test_top(request):
    run(**common_run_opts,
        sim_build = sim_dir/request.node.name,
        testcase = "top_test",
    )

@pytest.mark.skip(reason="Too much runtime")
def test_top_fpga_fe(request):
    common_run_opts["verilog_sources"] = [timescale_fix(root_dir/"work/top.yosys.v"), utils.run("yosys-config --datdir/ecp5/cells_sim.v")]
    common_run_opts["includes"] = [utils.run("yosys-config --datdir/ecp5")]
    run(**common_run_opts,
        sim_build = sim_dir/request.node.name,
        testcase = "top_wb2uart_test",
    )

