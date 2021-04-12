import pytest
from pathlib import Path
from cocotb_test.simulator import run
import os

import cocotb_utils as utils

root_dir = Path(__file__).resolve().parent.parent
sim_dir = root_dir/'sim'
rtl_dir = root_dir/'rtl'

def timescale_fix(verilog):
    verilog = Path(verilog)
    lines = verilog.read_text()
    if not any(['`timescale' in line for line in lines.splitlines()]):
        verilog.write_text("`timescale 1ns/1ps\n"+lines)
    return verilog

copperv_rtl=[ # replace by .flist ???
    rtl_dir/"copperv/idecoder.v",
    rtl_dir/"copperv/control_unit.v",
    rtl_dir/"copperv/execution.v",
    rtl_dir/"copperv/register_file.v",
    rtl_dir/"copperv/copperv.v",
]
top_rtl = [rtl_dir/"wishbone/copperv_wb.v",rtl_dir/"top.v"]
wb_adapter_rtl = [rtl_dir/"wishbone/wb_adapter.v"]
wb2uart_rtl = [rtl_dir/"uart/wb2uart.v"]

common_run_opts = dict(
    toplevel = "top",
    verilog_sources=top_rtl+copperv_rtl+wb_adapter_rtl+wb2uart_rtl,
    includes=[rtl_dir/'include'],
    module = "cocotb_tests",
    waves = True,
)

def test_top(request):
    run(**common_run_opts,
        sim_build = sim_dir/request.node.name,
        testcase = "top_wb2uart_test",
    )

@pytest.mark.skip(reason="Too much runtime")
def test_top_fpga_fe(request):
    common_run_opts["verilog_sources"] = [timescale_fix(root_dir/"work/top.yosys.v"), utils.run("yosys-config --datdir/ecp5/cells_sim.v")]
    common_run_opts["includes"] = [utils.run("yosys-config --datdir/ecp5")]
    run(**common_run_opts,
        sim_build = sim_dir/request.node.name,
        testcase = "top_wb2uart_test",
    )

