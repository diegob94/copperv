import pytest
from pathlib import Path
from cocotb_test.simulator import run

root_dir = Path(__file__).resolve().parent.parent
sim_dir = root_dir/'sim'
rtl_dir = root_dir/'rtl/wishbone'

wb_adapter_rtl = rtl_dir/"wb_adapter.v"
common_run_opts = dict(
    toplevel = "wb_adapter",
    verilog_sources=[wb_adapter_rtl],
    module = "cocotb_tests",
    waves = True,
    parameters=dict(data_width=32,addr_width=32),
)

def test_wishbone_adapter_read(request):
    run(
        **common_run_opts,
        sim_build = sim_dir/request.node.name,
        testcase = "wishbone_adapter_read_test",
    )

def test_wishbone_adapter_write(request):
    run(
        **common_run_opts,
        sim_build = sim_dir/request.node.name,
        testcase = "wishbone_adapter_write_test",
    )

