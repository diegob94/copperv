import logging
import dataclasses
import os
from pathlib import Path
from itertools import repeat

import cocotb
from cocotb.triggers import Join, Event, RisingEdge
from cocotb.log import SimLog
import toml
import cocotb_utils as utils
from bus import BusReadTransaction, CoppervBusRDriver, CoppervBusWDriver, BusWriteTransaction

from testbench import Testbench
from riscv_utils import compile_instructions, parse_data_memory, compile_riscv_test

from cocotbext.wishbone.monitor import WishboneSlave
from cocotb.clock import Clock
from cocotb.queue import Queue

root_dir = Path(__file__).resolve().parent.parent
sim_dir = root_dir/'sim'
toml_path = sim_dir/"tests/unit_tests.toml"
unit_tests = toml.loads(toml_path.read_text())

T_ADDR = 0x80000000
O_ADDR = 0x80000004
TC_ADDR = 0x80000008
T_PASS = 0x01000001
T_FAIL = 0x02000001

@dataclasses.dataclass
class TestParameters:
    name: str
    instructions: list = dataclasses.field(default_factory=list)
    expected_regfile_read: list = dataclasses.field(default_factory=list)
    expected_regfile_write: list = dataclasses.field(default_factory=list)
    expected_data_read: list = dataclasses.field(default_factory=list)
    expected_data_write: list = dataclasses.field(default_factory=list)
    data_memory: list = dataclasses.field(default_factory=list)
    def __repr__(self):
        p = '\n'.join([f"{k} = {repr(v)}" for k,v in dataclasses.asdict(self).items()])
        return '\n' + p

@cocotb.test(timeout_time=10,timeout_unit="us")
async def unit_test(dut):
    """ Copperv unit tests """
    test_name = os.environ['TEST_NAME']
    params = TestParameters(test_name,**unit_tests[test_name])
    SimLog("cocotb").setLevel(logging.DEBUG)

    instruction_memory = compile_instructions(params.instructions)
    data_memory = parse_data_memory(params.data_memory)
    tb = Testbench(dut,
        test_name,
        expected_data_read=params.expected_data_read,
        expected_data_write=params.expected_data_write,
        expected_regfile_read=params.expected_regfile_read,
        expected_regfile_write=params.expected_regfile_write,
        instruction_memory=instruction_memory,
        data_memory=data_memory)
    tb.start_clock()
    await tb.reset()
    await tb.finish()

@cocotb.test(timeout_time=100,timeout_unit="us")
async def riscv_test(dut):
    """ RISCV compliance tests """
    test_name = os.environ['TEST_NAME']
    asm_path = Path(os.environ['ASM_PATH'])
    SimLog("cocotb").setLevel(logging.DEBUG)

    instruction_memory, data_memory = compile_riscv_test(asm_path)
    tb = Testbench(dut,
        test_name,
        instruction_memory=instruction_memory,
        data_memory=data_memory,
        enable_self_checking=False,
        pass_fail_address = T_ADDR,
        pass_fail_values = {T_FAIL:False,T_PASS:True})

    tb.start_clock()
    await tb.reset()
    await tb.end_test.wait()

class AdapterTestbench:
    def __init__(self,dut,datGen):
        self._reset = dut.reset
        self.clock = dut.clock
        self.queue = Queue()
        period = 10
        period_unit = "ns"
        self.wbm = WishboneSlave(dut,"wb",dut.clock,datgen=datGen)
        self.bus_r = CoppervBusRDriver(clock=dut.clock,reset=dut.reset,entity=dut,prefix="bus")
        self.bus_w = CoppervBusWDriver(clock=dut.clock,reset=dut.reset,entity=dut,prefix="bus")
        cocotb.start_soon(Clock(dut.clock,period,period_unit).start())
    async def reset(self):
        await RisingEdge(self.clock)
        self._reset.value = 1
        await RisingEdge(self.clock)
        self._reset.value = 0
    def send_read(self,transaction):
        self.bus_r.append(transaction,callback=self.callback)
    def send_write(self,transaction):
        self.bus_w.append(transaction,callback=self.callback)
    async def receive(self):
        wb_transaction = await self.wbm.wait_for_recv()
        bus_transaction = await self.queue.get()
        return bus_transaction, wb_transaction
    def callback(self,transaction):
        self.queue.put_nowait(transaction)

@cocotb.test(timeout_time=1,timeout_unit="us")
async def wishbone_adapter_read_test(dut):
    """ Wishbone adapter read test """
    SimLog("cocotb").setLevel(logging.DEBUG)
    data = 101
    addr = 123
    datGen = repeat(data)
    tb = AdapterTestbench(dut,datGen)
    await tb.reset()
    tb.send_read(BusReadTransaction("bus_r",addr=addr))
    bus_transaction,wb_transaction = await tb.receive()
    assert wb_transaction[0].adr == addr
    assert wb_transaction[0].datrd == data
    assert bus_transaction.addr == addr
    assert bus_transaction.data == data

@cocotb.test(timeout_time=1,timeout_unit="us")
async def wishbone_adapter_write_test(dut):
    """ Wishbone adapter write test """
    data = 101
    addr = 123
    strobe = 0b0100
    resp = 1
    datGen = repeat(resp)
    tb = AdapterTestbench(dut,datGen)
    await tb.reset()
    tb.send_write(BusWriteTransaction("bus_w",data=data,addr=addr,strobe=strobe))
    bus_transaction,wb_transaction = await tb.receive()
    assert wb_transaction[0].adr == addr
    assert wb_transaction[0].datwr == data
    assert wb_transaction[0].sel == strobe
    assert wb_transaction[0].ack == True
    assert bus_transaction.addr == addr
    assert bus_transaction.data == data
    assert bus_transaction.strobe == strobe
    assert bus_transaction.response == 1

