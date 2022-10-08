import pytest
from pathlib import Path
from cocotb_test.simulator import run

root_dir = Path(__file__).resolve().parent.parent
sim_dir = root_dir/'sim'
rtl_dir = root_dir/'rtl/uart'

def timescale_fix(verilog):
    verilog = Path(verilog)
    lines = verilog.read_text()
    if not any(['timescale' in line for line in lines.splitlines()]):
        verilog.write_text("`timescale 1ns/1ps\n"+lines)
    return verilog

dut_rtl = timescale_fix(rtl_dir/"wb2uart.v")
common_run_opts = dict(
    toplevel = "wb2uart",
    verilog_sources=[dut_rtl],
    module = "cocotb_tests",
    waves = True,
    parameters=dict(data_width=32,addr_width=32),
)

def test_wb2uart_read():
    run(
        **common_run_opts,
        sim_build=f"work/sim/test_wb2uart_read",
        testcase = "wb2uart_read_test",
    )

def test_wb2uart_write():
    run(
        **common_run_opts,
        sim_build=f"work/sim/test_wb2uart_write",
        testcase = "wb2uart_write_test",
    )

