import cocotb
from bus import BusMonitor, BusReadTransaction, BusWriteTransaction, CoppervBusBfm
from regfile import RegFileWriteMonitor, RegFileReadMonitor, RegFileBfm
from cocotb.log import SimLog
import logging
from cocotb.triggers import RisingEdge
from riscv_utils import StackMonitor, PcMonitor

@cocotb.test()
async def wrapper(dut):
    """Wrapper for adding python monitors for debugging."""
    SimLog("cocotb").setLevel(logging.DEBUG)
    #SimLog("bfm").setLevel(logging.DEBUG)
    prefix = None
    core = dut.dut
    if not cocotb.plusargs.get('dut_copperv1',False):
        prefix = "bus_"
    clock = core.clk
    reset_n = core.rst
    bus_bfm = CoppervBusBfm(
        clock = clock,
        reset_n = reset_n,
        entity = core,
        prefix = prefix,
        relaxed_mode = True
    )
    regfile_bfm = RegFileBfm(
        clock = clock,
        reset_n = reset_n,
        entity = core.regfile,
        signals = RegFileBfm.Signals(
            rd_en = "rd_en",
            rd_addr = "rd",
            rd_data = "rd_din",
            rs1_en = "rs1_en",
            rs1_addr = "rs1",
            rs1_data = "rs1_dout",
            rs2_en = "rs2_en",
            rs2_addr = "rs2",
            rs2_data = "rs2_dout",
        )
    )
    bus_ir_monitor = BusMonitor("bus_ir",BusReadTransaction,bus_bfm.ir_get_request,bus_bfm.ir_get_response)
    bus_ir_req_monitor = BusMonitor("bus_ir_req",BusReadTransaction,bus_bfm.ir_get_request)
    bus_dr_monitor = BusMonitor("bus_dr",BusReadTransaction,bus_bfm.dr_get_request,bus_bfm.dr_get_response)
    bus_dr_req_monitor = BusMonitor("bus_dr_req",BusReadTransaction,bus_bfm.dr_get_request)
    bus_dw_monitor = BusMonitor("bus_dw",BusWriteTransaction,bus_bfm.dw_get_request,bus_bfm.dw_get_response)
    bus_dw_req_monitor = BusMonitor("bus_dw_req",BusWriteTransaction,bus_bfm.dw_get_request)
    regfile_write_monitor = RegFileWriteMonitor("regfile_write",regfile_bfm)
    regfile_read_monitor = RegFileReadMonitor("regfile_read",regfile_bfm)
    pc_monitor = PcMonitor('pc_monitor',core.pc)
    StackMonitor(regfile_write_monitor, pc_monitor)
    while True:
        await RisingEdge(dut.finish_cocotb)
        if dut.finish_cocotb.value.binstr == '1':
            break


