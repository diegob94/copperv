import pytest
from pathlib import Path
from cocotb_test.simulator import run
import os

root_dir = Path(__file__).resolve().parent.parent
sim_dir = root_dir/'sim'
rtl_dir = root_dir/'rtl'

copperv_rtl=[ # replace by .flist ???
    rtl_dir/"copperv/idecoder.v",
    rtl_dir/"copperv/control_unit.v",
    rtl_dir/"copperv/execution.v",
    rtl_dir/"copperv/register_file.v",
    rtl_dir/"copperv/copperv.v",
]
top_rtl = [rtl_dir/"copperv/copperv_wb.v",rtl_dir/"top.v"]
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
        testcase = "top_c_nop_test",
    )

