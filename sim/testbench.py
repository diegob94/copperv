import cocotb
from cocotb.log import SimLog
from cocotb_bus.scoreboard import Scoreboard
from cocotb.triggers import RisingEdge, ClockCycles, Event
from pathlib import Path
from tabulate import tabulate
from cocotb.clock import Clock

from bus import BusReadTransaction, BusWriteTransaction, CoppervBusIrMonitor, CoppervBusDrMonitor, CoppervBusDwMonitor
from regfile import RegFileReadMonitor, RegFileWriteMonitor, RegFileReadTransaction, RegFileWriteTransaction
from cocotb_utils import from_array, to_bytes

class Testbench():
    def __init__(self, dut,
            test_name,
            expected_regfile_read = None,
            expected_regfile_write = None,
            expected_data_read = None,
            expected_data_write = None,
            instruction_memory = {},
            data_memory = {},
            enable_self_checking = True,
            pass_fail_address = None,
            pass_fail_values = None,
            output_address = None,
            passive_mode = False,
        ):
        self.period = 10
        self.period_unit = "ns"
        self.log = SimLog('cocotb.'+__name__+'.'+self.__class__.__name__)
        self.test_name = test_name
        self.dut = dut
        self.clock = self.dut.clk
        self._reset_n = self.dut.rst
        self._reset_n.setimmediatevalue(0)
        self.pass_fail_address = pass_fail_address
        self.pass_fail_values = pass_fail_values
        self.output_address = output_address
        self.end_test = Event()
        ## Process parameters
        self.memory = {**instruction_memory,**data_memory}
        if 'debug_test' in cocotb.plusargs:
            csv_path = Path(test_name+'_memory.csv')
            self.log.debug(f"Dumping initial memory content to {csv_path.resolve()}")
            memory = [(f'0x{k:X}',f'0x{v:X}') for k,v in self.memory.items()]
            csv_path.write_text(tabulate(memory, ['address','value'], tablefmt="plain"))
        self.end_i_address = None
        if enable_self_checking:
            self.end_i_address = max(instruction_memory.keys())
            self.expected_regfile_read = [RegFileReadTransaction.from_string(t) for t in expected_regfile_read]
            self.expected_regfile_write = [RegFileWriteTransaction.from_string(t) for t in expected_regfile_write]
            self.expected_data_read = [BusReadTransaction.from_string(t) for t in expected_data_read]
            self.expected_data_write = [BusWriteTransaction.from_string(t) for t in expected_data_write]
        self.log.debug(f"Instruction memory: {instruction_memory}")
        self.log.debug(f"Data memory: {data_memory}")
        self.log.debug(f"Memory: {self.memory}")
        ## Bus functional models
        prefix = None
        monitor_opts = dict(
            clock = self.clock,
            reset_n = self._reset_n,
            entity = self.dut,
            prefix = prefix,
            resp_gen = self.memory_callback,
            passive_mode = passive_mode,
        )
        ## Instruction read
        self.bus_ir_monitor = CoppervBusIrMonitor(**monitor_opts)
        ## Data read
        self.bus_dr_monitor = CoppervBusDrMonitor(**monitor_opts)
        ## Data write
        self.bus_dw_monitor = CoppervBusDwMonitor(**monitor_opts)
        ## Regfile
        self.regfile_write_monitor = RegFileWriteMonitor(
            prefix=None,
            clock = self.clock,
            reset_n = self._reset_n,
            entity = self.dut.regfile,
            signals_dict = dict(
                rd_en = "rd_en",
                rd_addr = "rd",
                rd_data = "rd_din",
            )
        )
        self.regfile_read_monitor = RegFileReadMonitor(
            prefix=None,
            clock = self.clock,
            reset_n = self._reset_n,
            entity = self.dut.regfile,
            signals_dict = dict(
                rs1_en = "rs1_en",
                rs1_addr = "rs1",
                rs1_data = "rs1_dout",
                rs2_en = "rs2_en",
                rs2_addr = "rs2",
                rs2_data = "rs2_dout",
            )
        )
        if enable_self_checking:
            ## Self checking
            self.scoreboard = Scoreboard(dut)
            self.scoreboard.add_interface(self.regfile_write_monitor, self.expected_regfile_write)
            self.scoreboard.add_interface(self.regfile_read_monitor, self.expected_regfile_read)
            self.scoreboard.add_interface(self.bus_dr_monitor, self.expected_data_read)
            self.scoreboard.add_interface(self.bus_dw_monitor, self.expected_data_write)
    def start_clock(self):
        cocotb.start_soon(Clock(self.clock,self.period,self.period_unit).start())
    async def reset(self):
        if self._reset_n is not None:
            await RisingEdge(self.clock)
            self._reset_n.value = 0
            await RisingEdge(self.clock)
            self._reset_n.value = 1
    def memory_callback(self, transaction):
        self.log.debug(f"Memory callback {transaction}")
        if isinstance(transaction,BusReadTransaction) and transaction.bus_name == 'bus_ir':
            driver_transaction = "deassert_ready"
            if self.end_i_address is None or (self.end_i_address is not None and transaction.addr < self.end_i_address):
                driver_transaction = BusReadTransaction(
                    bus_name = transaction.bus_name,
                    data = from_array(self.memory,transaction.addr),
                    addr = transaction.addr)
            #self.log.debug('instruction_read_callback transaction: %s driver_transaction %s',
            #    transaction,driver_transaction)
        elif isinstance(transaction,BusReadTransaction) and transaction.bus_name == 'bus_dr':
            driver_transaction = BusReadTransaction(
                bus_name = transaction.bus_name,
                data = self.handle_data_read(transaction),
                addr = transaction.addr,
            )
            #self.log.debug('data_read_callback transaction: %s driver_transaction %s',
            #    transaction,driver_transaction)
        elif isinstance(transaction,BusWriteTransaction):
            self.handle_data_write(transaction)
            driver_transaction = BusWriteTransaction(
                bus_name = transaction.bus_name,
                data = transaction.data,
                addr = transaction.addr,
                strobe = transaction.strobe,
                response = 1,
            )
            #self.log.debug('data_write_callback transaction: %s driver_transaction %s',
            #    transaction,driver_transaction)
        else:
            raise ValueError(f"Unsupported transaction type: {transaction}")
        return driver_transaction
    def handle_data_write(self,transaction):
        if self.pass_fail_address is not None and self.pass_fail_address == transaction.addr:
            assert self.pass_fail_values[transaction.data] == True, "Received test fail from bus"
            self.log.debug("Received test pass from bus")
            self.end_test.set()
        else:
            mask = f"{transaction.strobe:04b}"
            #self.log.debug('write start: %X mask: %s',from_array(self.memory,transaction.addr),mask)
            for i in range(4):
                if int(mask[3-i]):
                    #self.log.debug('writing %X -> %X',transaction.addr+i,to_bytes(transaction.data)[i])
                    self.memory[transaction.addr+i] = to_bytes(transaction.data)[i]
            #self.log.debug('write finished: %X',from_array(self.memory,transaction.addr))
    def handle_data_read(self,transaction):
        return from_array(self.memory,transaction.addr)
    @cocotb.coroutine
    async def finish(self):
        last_pending = ""
        while True:
            if all([len(expected) == 0 for expected in self.scoreboard.expected.values()]):
                break
            pending = repr({k:[str(i) for i in v] for k,v in self.scoreboard.expected.items()})
            if last_pending != pending:
                self.log.debug(f"Pending transactions: {pending}")
            last_pending = pending
            await RisingEdge(self.clock)
        await ClockCycles(self.clock,2)
