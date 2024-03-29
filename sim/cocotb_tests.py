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
from cocotb_utils import APP_START_ADDR, O_ADDR, T_ADDR, T_PASS, T_FAIL
from bus import BusReadTransaction, CoppervBusRDriver, CoppervBusWDriver, BusWriteTransaction

from testbench import Testbench
from riscv_utils import PcMonitor, StackMonitor, compile_instructions, parse_data_memory, compile_riscv_test, process_elf, read_elf, elf_to_memory

from cocotbext.uart import UartSource, UartSink
from cocotbext.wishbone.monitor import WishboneSlave
from cocotbext.wishbone.driver import WishboneMaster, WBOp
from cocotb.clock import Clock
from cocotb.queue import Queue

root_dir = Path(__file__).resolve().parent.parent
sim_dir = root_dir/'sim'
toml_path = sim_dir/"tests/unit_tests.toml"
unit_tests = toml.loads(toml_path.read_text())

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

class Wb2uartMonitor:
    def __init__(self,tx,rx,baud=115200,resp_callback=None):
        self.log = SimLog(f"cocotb.{type(self).__qualname__}")
        self.tx = tx
        self.rx = rx
        self.source = UartSource(self.rx, baud=baud, bits=8)
        self.sink = UartSink(self.tx, baud=baud, bits=8)
        self.resp_callback = resp_callback
        self._assert_coro = None
        self.recvQ = Queue()
        cocotb.start_soon(self.run())
    async def receive(self,count=4):
        if self._assert_coro is not None:
            self._assert_coro.kill()
        recv = await self.sink.read(count)
        self._assert_coro = cocotb.start_soon(assert_hold(self.tx))
        data = int.from_bytes(recv, byteorder='little', signed=False)
        return data
    def send(self,data):
        self.source.write_nowait(data)
    async def read(self):
        return await self.recvQ.get()
    async def run(self):
        while True:
            op = await self.receive(1)
            address = await self.receive()
            data = None
            sel = None
            if op == 1:
                data = await self.receive()
                sel = await self.receive(1)
            if self.resp_callback is not None:
                resp = self.resp_callback(op,address,data,sel)
                self.send(resp)
                resp = int.from_bytes(resp,byteorder='little')
            info = f"transaction: address = 0x{address:X}"
            if op == 1:
                info = "Write " + info + f" data = 0x{data:X} sel = 0x{sel:X}"
            else:
                info = "Read " + info
            info = info + f" resp = 0x{resp:X}"
            self.log.info(info)
            self.recvQ.put_nowait(dict(op=op,address=address,data=data,sel=sel))

class Wb2uartTestbench:
    def __init__(self,dut,resp_callback):
        self.clock = dut.clock
        self._reset = dut.reset
        self.queue = Queue()
        period = 40
        period_unit = "ns"
#       cocotb.start_soon(monitor(dut._log,dut.uart_tx))
        self.uart = Wb2uartMonitor(dut.uart_tx,dut.uart_rx,resp_callback=resp_callback)
        self.wb = WishboneMaster(dut, "wb", dut.clock, width=32)
        cocotb.start_soon(Clock(dut.clock,period,period_unit).start())
    async def reset(self):
        await RisingEdge(self.clock)
        self._reset.value = 1
        await RisingEdge(self.clock)
        self._reset.value = 0
    async def _send(self,ops):
        res = await self.wb.send_cycle(ops)
        self.queue.put_nowait(res)
    def send_wb(self,transaction):
        cocotb.start_soon(self._send([transaction]))
    async def receive_wb(self):
        wb_transaction = await self.queue.get()
        return wb_transaction[0]

@cocotb.test(timeout_time=2,timeout_unit='ms')
async def wb2uart_read_test(dut):
    """ Wishbone to UART adapter read test """
    op = 0
    data = int(os.environ['TEST_DATA'])
    addr = int(os.environ['TEST_ADDR'])
    resp_callback = lambda op,addr,data,sel,_data=data: _data.to_bytes(4, byteorder='little')
    tb = Wb2uartTestbench(dut,resp_callback)
    await tb.reset()
    tb.send_wb(WBOp(adr=addr))
    uart = await tb.uart.read()
    assert uart["op"] == op, f"UART received wrong op: 0x{uart['op']:X} != 0x{op:X}"
    assert uart["address"] == addr, f"UART received wrong address: 0x{uart['address']:X} != 0x{addr:X}"
    wb_transaction = await tb.receive_wb()
    assert wb_transaction.datrd == data, f"WB received wrong data: 0x{wb_transaction.datrd.integer:X} != 0x{data:X}"

@cocotb.test(timeout_time=2,timeout_unit='ms')
async def wb2uart_write_test(dut):
    """ Wishbone to UART adapter write test """
    op = 1
    data = 101
    addr = 123
    sel = 0b0100
    ack = 1
    resp_callback = lambda op,addr,data,sel,_ack=ack: _ack.to_bytes(1, byteorder='little')
    tb = Wb2uartTestbench(dut,resp_callback)
    await tb.reset()
    tb.send_wb(WBOp(adr=addr,dat=data,sel=sel))
    uart = await tb.uart.read()
    assert uart["op"] == op, f"UART received wrong op: 0x{uart['op']:X} != 0x{op:X}"
    assert uart["address"] == addr, f"UART received wrong address: 0x{uart['address']:X} != 0x{addr:X}"
    assert uart["data"] == data, f"UART received wrong data: 0x{uart['data']:X} != 0x{data:X}"
    assert uart["sel"] == sel, f"UART received wrong sel: 0x{uart['sel']:X} != 0x{sel:X}"
    wb_transaction = await tb.receive_wb()
    assert wb_transaction.ack == ack, f"WB received wrong ack: 0x{wb_transaction.ack:X} != 0x{ack:X}"

class TopTestbench:
    def __init__(self,dut,resp_callback = None, elf_path = None):
        self.clock = dut.clock
        self._reset = dut.reset
        period = 40
        period_unit = "ns"
        self.uart = Wb2uartMonitor(dut.uart_tx,dut.uart_rx,resp_callback=resp_callback)
        cocotb.start_soon(Clock(dut.clock,period,period_unit).start())
        copperv_tb = Testbench(dut.cpu.core,"top_test",enable_self_checking=False,passive_mode=True)
        pc_monitor = PcMonitor("PcMonitor", dut.cpu.core.pc)
        stack_monitor = StackMonitor(copperv_tb.regfile_write_monitor, pc_monitor, elf_path = elf_path)
    async def reset(self):
        await RisingEdge(self.clock)
        self._reset.value = 1
        await RisingEdge(self.clock)
        self._reset.value = 0

class VirtualMemory:
    def __init__(self,boot_memory,app_memory,end_test_callback):
        self.log = SimLog(f"cocotb.{type(self).__qualname__}")
        self.end_test = end_test_callback
        self.BOOTLOADER_SIZE = APP_START_ADDR
        self.first_word = True
        self.bootloader_offset = self.BOOTLOADER_SIZE
        self.uart_queue = Queue()
        self.boot_memory = boot_memory
        self.app_memory = app_memory
    def __str__(self):
        return f"VirtualMemory: boot size = {len(self.boot_memory)} / app size = {len(self.app_memory)}"
    def __call__(self,op,address,data,sel):
        if op == 0: # read
            if address == self.BOOTLOADER_SIZE - 4:
                if self.first_word:
                    self.first_word = False
                    return len(self.app_memory).to_bytes(4,byteorder='little')
                word = utils.from_array(self.app_memory,self.bootloader_offset)
                self.bootloader_offset += 4
                return word.to_bytes(4,byteorder='little')
            return utils.from_array(self.boot_memory,address).to_bytes(4,byteorder='little')
        elif op == 1: # write
            if address == T_ADDR:
                assert data == T_PASS, "Received test fail from bus"
                self.end_test()
            elif address == O_ADDR:
                self.uart_queue.put_nowait(data & 0xFF)
                print(f"uart: {repr(chr(data))} {data}")
            else:
                mask = f"{sel:04b}"
                for i in range(4):
                    if int(mask[3-i]):
                        self.boot_memory[address+i] = utils.to_bytes(data)[i]
            return (1).to_bytes(1,byteorder='little')

@cocotb.test(timeout_time=100,timeout_unit="ms")
async def top_test(dut):
    SimLog("cocotb").setLevel(logging.DEBUG)
    elf_path = os.environ['ELF_PATH']
    imem,dmem = process_elf(elf_path)
    boot_elf = read_elf(elf_path,sections=['.boot'])
    boot_memory = elf_to_memory(boot_elf)
    app_memory = {**imem,**dmem}
    end_test = Event()
    memory_callback = VirtualMemory(boot_memory,app_memory,lambda end_test=end_test: end_test.set())
    tb = TopTestbench(dut,memory_callback,elf_path=elf_path)
    await tb.reset()
    await end_test.wait()
    buffer = ""
    while not memory_callback.uart_queue.empty():
        buffer += chr(memory_callback.uart_queue.get_nowait())
    if "hello_world" in elf_path:
        assert buffer == "Hello world 1\nHello world 2\n"

@cocotb.test(timeout_time=100,timeout_unit="ms")
async def top_test_bootloader_return_zero(dut):
    SimLog("cocotb").setLevel(logging.DEBUG)
    elf_path = os.environ['ELF_PATH']
    imem,dmem = process_elf(elf_path)
    boot_elf = read_elf(elf_path,sections=['.boot'])
    boot_memory = elf_to_memory(boot_elf)
    i_end_addr = max(list(imem.keys()))
    dmem = {
        i_end_addr+1:0x00,
        i_end_addr+2:0x00,
        i_end_addr+3:0x00,
        i_end_addr+4:0x00,
    }
    app_memory = {**imem,**dmem}
    end_test = Event()
    memory_callback = VirtualMemory(boot_memory,app_memory,lambda end_test=end_test: end_test.set())
    tb = TopTestbench(dut,memory_callback,elf_path=elf_path)
    await tb.reset()
    await end_test.wait()

