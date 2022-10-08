import logging
import dataclasses
import os
from pathlib import Path
from itertools import repeat

import cocotb
from cocotb.triggers import Join, Event, RisingEdge, Edge
from cocotb.log import SimLog
import toml
import cocotb_utils as utils
from bus import BusReadTransaction, CoppervBusRDriver, CoppervBusWDriver, BusWriteTransaction

from testbench import Testbench
from riscv_utils import compile_instructions, parse_data_memory, compile_riscv_test

from cocotbext.uart import UartSource, UartSink
from cocotbext.wishbone.monitor import WishboneSlave
from cocotbext.wishbone.driver import WishboneMaster, WBOp
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
        self.clock = dut.clock
        self._reset = dut.reset
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

async def monitor(log,signal):
    while True:
        await Edge(signal)
        log.info("%s = %d",signal.name,signal.value)

async def assert_hold(signal):
    await Edge(signal)
    assert False, "Unexpected transition"

class Wb2uartTestbench:
    def __init__(self,dut):
        self.clock = dut.clock
        self._reset = dut.reset
        self.uart_tx = dut.uart_tx
        self.queue = Queue()
        period = 40
        period_unit = "ns"
#       cocotb.start_soon(monitor(dut._log,dut.uart_tx))
        self.wb = WishboneMaster(dut, "wb", dut.clock, width=32)
        self.uart_source = UartSource(dut.uart_rx, baud=115200, bits=8)
        self.uart_sink = UartSink(dut.uart_tx, baud=115200, bits=8)
        cocotb.start_soon(Clock(dut.clock,period,period_unit).start())
        self._assert_coro = None
    async def reset(self):
        await RisingEdge(self.clock)
        self._reset.value = 1
        await RisingEdge(self.clock)
        self._reset.value = 0
    async def _send(self,ops):
        res = await self.wb.send_cycle(ops)
        self.queue.put_nowait(res)
    def send(self,transaction):
        cocotb.start_soon(self._send([transaction]))
    async def receive_uart(self,count=4):
        if self._assert_coro is not None:
            self._assert_coro.kill()
        recv = await self.uart_sink.read(count)
        self._assert_coro = cocotb.start_soon(assert_hold(self.uart_tx))
        data = int.from_bytes(recv, byteorder='little', signed=False)
        return data
    def send_uart(self,data):
        self.uart_source.write_nowait(data.to_bytes(4,byteorder='little'))
    async def receive_wb(self):
        wb_transaction = await self.queue.get()
        return wb_transaction[0]

@cocotb.test(timeout_time=2,timeout_unit='ms')
async def wb2uart_read_test(dut):
    """ Wishbone to UART adapter read test """
    op = 0
    data = 101
    addr = 123
    tb = Wb2uartTestbench(dut)
    await tb.reset()
    tb.send(WBOp(adr=addr))
    uart_op = await tb.receive_uart(1)
    uart_address = await tb.receive_uart()
    assert uart_op == op, f"UART received wrong op: 0x{uart_op:X} != 0x{op:X}"
    assert uart_address == addr, f"UART received wrong address: 0x{uart_address:X} != 0x{addr:X}"
    tb.send_uart(data)
    wb_transaction = await tb.receive_wb()
    assert wb_transaction.datrd == data, f"WB received wrong data: 0x{wb_transaction.datrd:X} != 0x{data:X}"

@cocotb.test(timeout_time=2,timeout_unit='ms')
async def wb2uart_write_test(dut):
    """ Wishbone to UART adapter write test """
    op = 1
    data = 101
    addr = 123
    sel = 0b0100
    ack = 1
    tb = Wb2uartTestbench(dut)
    await tb.reset()
    tb.send(WBOp(adr=addr,dat=data,sel=sel))
    uart_op = await tb.receive_uart(1)
    uart_address = await tb.receive_uart()
    uart_data = await tb.receive_uart()
    uart_sel = await tb.receive_uart(1)
    assert uart_op == op, f"UART received wrong op: 0x{uart_op:X} != 0x{op:X}"
    assert uart_address == addr, f"UART received wrong address: 0x{uart_address:X} != 0x{addr:X}"
    assert uart_data == data, f"UART received wrong data: 0x{uart_data:X} != 0x{data:X}"
    assert uart_sel == sel, f"UART received wrong sel: 0x{uart_sel:X} != 0x{sel:X}"
    tb.send_uart(ack)
    wb_transaction = await tb.receive_wb()
    assert wb_transaction.ack == ack, f"WB received wrong ack: 0x{wb_transaction.ack:X} != 0x{ack:X}"

