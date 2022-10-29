import pytest
from pathlib import Path
from cocotb_test.simulator import run
from itertools import product

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

@pytest.mark.parametrize(
    "parameters", [pytest.param({"TEST_DATA":str(data),"TEST_ADDR":str(addr)}) for data,addr in product([101,0],[123,0])]
)
def test_wb2uart_read(request,parameters):
    run(
        **common_run_opts,
        extra_env=parameters,
        sim_build = sim_dir/request.node.name,
        testcase = "wb2uart_read_test",
    )

def test_wb2uart_write(request):
    run(
        **common_run_opts,
        sim_build = sim_dir/request.node.name,
        testcase = "wb2uart_write_test",
    )

