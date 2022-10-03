import pytest
from pathlib import Path
from cocotb_test.simulator import run

root_dir = Path(__file__).resolve().parent.parent
sim_dir = root_dir/'sim'
rtl_dir = root_dir/'rtl/uart'

dut_rtl = rtl_dir/"wb2uart.v"
common_run_opts = dict(
    toplevel = "wb2uart",
    verilog_sources=[dut_rtl],
    module = "cocotb_tests",
    waves = True,
    parameters=dict(data_width=32,addr_width=32),
)

def test_wb2uart_read(request):
    run(
        **common_run_opts,
        sim_build = sim_dir/request.node.name,
        testcase = "wb2uart_read_test",
    )

def test_wb2uart_write(request):
    run(
        **common_run_opts,
        sim_build = sim_dir/request.node.name,
        testcase = "wb2uart_write_test",
    )

