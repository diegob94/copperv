import pytest
from pathlib import Path
from cocotb_test.simulator import run

root_dir = Path(__file__).resolve().parent.parent
sim_dir = root_dir/'sim'
rtl_dir = root_dir/'rtl/wishbone'

def timescale_fix(verilog):
    verilog = Path(verilog)
    lines = verilog.read_text()
    if not any(['timescale' in line for line in lines.splitlines()]):
        verilog.write_text("`timescale 1ns/1ps\n"+lines)
    return verilog

wb_adapter_rtl = timescale_fix(rtl_dir/"wb_adapter.v")
common_run_opts = dict(
    toplevel = "WishboneAdapter",
    verilog_sources=[wb_adapter_rtl],
    module = "cocotb_tests",
    waves = True,
)

@pytest.mark.skip(reason="Wishbone adapter is not implemented")
def test_wishbone_adapter_read():
    run(
        **common_run_opts,
        sim_build=f"work/sim/test_wishbone_adapter_read",
        testcase = "wishbone_adapter_read_test",
    )

@pytest.mark.skip(reason="Wishbone adapter is not implemented")
def test_wishbone_adapter_write():
    run(
        **common_run_opts,
        sim_build=f"work/sim/test_wishbone_adapter_write",
        testcase = "wishbone_adapter_write_test",
    )

