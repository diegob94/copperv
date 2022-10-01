import logging
from typing import Tuple
import cocotb
from cocotb.decorators import RunningTask
from cocotb.triggers import First, Join, PythonTrigger
import pyuvm as uvm
import random
import dataclasses
from types import SimpleNamespace

def convert2string(self,**kwargs: Tuple[int,str]):
    res = f'{self.get_name()} : '
    for attr,properties in kwargs.items():
        if not hasattr(self,attr):
            continue
        width,format = properties
        divide_by = 1
        if format.lower() == 'x':
            divide_by = 4
        value = getattr(self,attr)
        string = None
        if value is not None:
            string = f'0x{value:0{width//divide_by}{format}}'
        res += f'{attr}: {string} '
    return res

class WbSeqItem(uvm.uvm_sequence_item):
    def __init__(self, name):
        super().__init__(name)
        self.addr_width = 32
        self.data_width = 32
        self.granularity = 8
        self.sel_width = self.data_width // self.granularity
    def __str__(self):
        return convert2string(self,
            data=(self.data_width,'X'),
            addr=(self.addr_width,'X'),
            sel=(self.sel_width,'b'),
            ack=(1,'b')
        )

class WbReadSeqItem(WbSeqItem):
    def __init__(self, name):
        super().__init__(name)
        self.addr = None
        self.data = None
        self.ack = None
    def __eq__(self,other):
        return self.addr == other.addr and self.data == other.data \
            and self.ack == other.ack
    def randomize(self):
        self.addr = random.randint(0, (2**self.addr_width)-1)

class WbWriteSeqItem(WbSeqItem):
    def __init__(self, name):
        super().__init__(name)
        self.addr = None
        self.data = None
        self.sel = None
        self.ack = None
    def __eq__(self,other):
        return self.addr == other.addr and self.data == other.data \
            and self.sel == other.sel and self.ack == other.ack
    def randomize(self):
        self.addr = random.randint(0, (2**self.addr_width)-1)
        self.data = random.randint(0, (2**self.data_width)-1)
        self.sel = random.randint(0, (2**self.sel_width)-1)

class BusSeqItem(uvm.uvm_sequence_item):
    def __init__(self, name):
        super().__init__(name)
        self.addr_width = 32
        self.data_width = 32
        self.strobe_width = self.data_width // 8
        self.resp_width = 1
    def __str__(self):
        return convert2string(self,
            data=(self.data_width,'X'),
            addr=(self.addr_width,'X'),
            strobe=(self.strobe_width,'b'),
            resp=(self.resp_width,'X')
        )

class BusReadSeqItem(BusSeqItem):
    def __init__(self, name):
        super().__init__(name)
        self.addr = None
        self.data = None
    def __eq__(self,other):
        return self.addr == other.addr and self.data == other.data
    def randomize(self):
        self.addr = random.randint(0, (2**self.addr_width)-1)

class BusWriteSeqItem(BusSeqItem):
    def __init__(self, name):
        super().__init__(name)
        self.addr = None
        self.data = None
        self.strobe = None
        self.resp = None
    def __eq__(self, other):
        return self.addr == other.addr and self.data == other.data \
            and self.strobe == other.strobe and self.resp == other.resp
    def randomize(self):
        self.addr = random.randint(0, (2**self.addr_width)-1)
        self.data = random.randint(0, (2**self.data_width)-1)
        self.strobe = random.randint(0, (2**self.strobe_width)-1)

class BusSeq(uvm.uvm_sequence):
    async def body(self):
        for _ in range(10):
            bus_read_tr = BusReadSeqItem("bus_read_tr")
            await self.start_item(bus_read_tr)
            bus_read_tr.randomize()
            await self.finish_item(bus_read_tr)
            bus_write_tr = BusWriteSeqItem("bus_write_tr")
            await self.start_item(bus_write_tr)
            bus_write_tr.randomize()
            await self.finish_item(bus_write_tr)

@dataclasses.dataclass
class ScoreboardConfig:
    input_count: int = 1

class Scoreboard(uvm.uvm_component):
    def __init__(self, name, parent, config):
        super().__init__(name, parent)
        self.config = config
    def build_phase(self):
        self.fifos = [SimpleNamespace(
            ref=uvm.uvm_tlm_analysis_fifo(f"ref_fifo_{i}", self),
            dut=uvm.uvm_tlm_analysis_fifo(f"dut_fifo_{i}", self)) 
            for i in range(self.config.input_count)]
        self.ports = [SimpleNamespace(
            ref=uvm.uvm_get_port(f"ref_port_{i}", self),
            dut=uvm.uvm_get_port(f"dut_port_{i}", self)) 
            for i in range(self.config.input_count)]
        self.exports = [SimpleNamespace(
            ref=fifo.ref.analysis_export,
            dut=fifo.dut.analysis_export)
            for fifo in self.fifos]
    def connect_phase(self):
        for port,fifo in zip(self.ports,self.fifos):
            port.ref.connect(fifo.ref.get_export)
            port.dut.connect(fifo.dut.get_export)
    def check_phase(self):
        for port in self.ports:
            while port.ref.can_get():
                _, ref = port.ref.try_get()
                dut_success, dut = port.dut.try_get()
                if not dut_success:
                    self.logger.critical(f"Reference transaction {ref} had no DUT transaction")
                    assert False
                else:
                    if ref == dut:
                        self.logger.info(f"PASSED: {ref} == {dut}")
                    else:
                        self.logger.error(f"FAILED: {ref} != {dut}")
                        assert False

class uvm_AnalysisImp(uvm.uvm_analysis_export):
    def __init__(self, name, parent, write_fn):
        super().__init__(name, parent)
        self.write_fn = write_fn
    def write(self,data):
        return self.write_fn(data)

class WbAdapterRefModel(uvm.uvm_component):
    def build_phase(self):
        self.resp_ap = uvm.uvm_analysis_port("resp_ap", self)
        self.req_ap = uvm.uvm_analysis_port("req_ap", self)
        self.req_export = uvm_AnalysisImp("req_export",self,self.write)
        self.resp_export = uvm_AnalysisImp("resp_export",self,self.write)
    def write(self, data):
        if isinstance(data,WbReadSeqItem):
            ref = BusReadSeqItem(data.get_name())
            ref.addr = data.addr
            ref.data = data.data
        if isinstance(data,WbWriteSeqItem):
            ref = BusWriteSeqItem(data.get_name())
            ref.addr = data.addr
            ref.data = data.data
            ref.strobe = data.sel
            ref.resp = data.ack
        self.logger.debug(f"WbAdapterRefModel write: {data} -> {ref}")
        self.ref_ap.write(ref)

class WbMonitor(uvm.uvm_component):
    def __init__(self, name, parent):
        super().__init__(name, parent)
    def build_phase(self):
        self.req_ap = uvm.uvm_analysis_port("req_ap", self)
        self.resp_ap = uvm.uvm_analysis_port("resp_ap", self)
    def connect_phase(self):
        self.bfm = self.cdb_get("BFM")
    async def run_phase(self):
        while True:
            datum = await anext(self.bfm.sink_receive())
            self.logger.debug(f"Receiving request: {datum}")
            self.req_ap.write(datum)
            datum = await anext(self.bfm.source_receive())
            self.logger.debug(f"Receiving response: {datum}")
            self.resp_ap.write(datum)

class WbResponseDriver(uvm.uvm_driver):
    def connect_phase(self):
        self.bfm = self.cdb_get("BFM")
    async def run_phase(self):
        while True:
            seq_item = await self.seq_item_port.get_next_item()
            if isinstance(seq_item,WbReadSeqItem):
                await self.bfm.source_read(addr=seq_item.addr)
            if isinstance(seq_item,WbWriteSeqItem):
                await self.bfm.source_write(addr=seq_item.addr,data=seq_item.data,sel=seq_item.sel)
            self.logger.debug(f"Sent WB request: {seq_item}")
            self.seq_item_port.item_done()

class WbSinkAgent(uvm.uvm_agent):
    def build_phase(self):
        self.req_ap = uvm.uvm_analysis_port("req_ap", self)
        self.resp_ap = uvm.uvm_analysis_port("resp_ap", self)
        self.mon = WbMonitor("mon", self)
        if self.active:
            self.driver = WbResponseDriver("driver", self)
            self.seqr = uvm.uvm_sequencer("seqr", self)
            self.cdb_set("SEQR",self.seqr,"")
    def connect_phase(self):
        self.req_ap.connect(self.mon.req_ap)
        self.resp_ap.connect(self.mon.resp_ap)
        if self.active:
            self.driver.seq_item_port.connect(self.seqr.seq_item_export)

# Sink and Source:
## Request = read -> addr, write -> req
## Response = read -> data, write -> resp

class BusRequestDriver(uvm.uvm_driver):
    def connect_phase(self):
        self.bfm = self.cdb_get("BFM")
    async def run_phase(self):
        while True:
            seq_item = await self.seq_item_port.get_next_item()
            if isinstance(seq_item,BusReadSeqItem):
                await self.bfm.send_read_request(addr=seq_item.addr)
            if isinstance(seq_item,BusWriteSeqItem):
                await self.bfm.send_write_request(addr=seq_item.addr,data=seq_item.data,strobe=seq_item.strobe)
            self.logger.debug(f"Sent bus request: {seq_item}")
            self.seq_item_port.item_done()

class BusMonitor(uvm.uvm_component):
    def __init__(self, name, parent, method):
        super().__init__(name, parent)
        self.method = method
    def build_phase(self):
        self.ap = uvm.uvm_analysis_port("ap", self)
    def connect_phase(self):
        self.bfm = self.cdb_get("BFM")
        self.get_read = getattr(self.bfm,'get_read_'+self.method)
        self.get_write = getattr(self.bfm,'get_write_'+self.method)
    async def run_phase(self):
        while True:
            datum = await First(anext(self.get_read()),anext(self.get_write()))
            self.logger.debug(f"Receiving bus {self.method}: {datum}")
            self.ap.write(datum)

class BusSourceAgent(uvm.uvm_agent):
    def __init__(self, name, parent):
        super().__init__(name, parent)
    def build_phase(self):
        self.req_ap = uvm.uvm_analysis_port("req_ap", self)
        self.resp_ap = uvm.uvm_analysis_port("resp_ap", self)
        self.req_mon = BusMonitor("req_mon", self, 'request')
        self.resp_mon = BusMonitor("resp_mon", self, 'response')
        if self.active:
            self.req_driver = BusRequestDriver("req_driver", self)
            self.seqr = uvm.uvm_sequencer("seqr", self)
            self.cdb_set("SEQR",self.seqr,"")
    def connect_phase(self):
        self.req_mon.ap.connect(self.req_ap)
        self.resp_mon.ap.connect(self.resp_ap)
        if self.active:
            self.req_driver.seq_item_port.connect(self.seqr.seq_item_export)

class Debugger(uvm.uvm_subscriber):
    def write(self,data):
        print(f'DEBUGGER: {self.get_full_name()}:',data)

class WbAdapterEnv(uvm.uvm_env):
    def build_phase(self):
        scoreboard_config = ScoreboardConfig(input_count=2)
        self.bus_agent = BusSourceAgent("bus_agent", self)
        self.wb_agent = WbSinkAgent("wb_agent", self)
        self.scoreboard = Scoreboard("scoreboard", self, scoreboard_config)
        self.ref_model = WbAdapterRefModel('ref_model',self)
    def connect_phase(self):
        print(self.scoreboard.fifos[1].dut.analysis_export,self.scoreboard.exports[1].dut)
        self.bus_agent.resp_ap.connect(self.scoreboard.exports[0].dut)
        self.ref_model.resp_ap.connect(self.scoreboard.exports[0].ref)
        self.bus_agent.req_ap.connect(self.scoreboard.exports[1].ref)
        self.ref_model.req_ap.connect(self.scoreboard.exports[1].dut)
        self.wb_agent.resp_ap.connect(self.ref_model.resp_export)
        self.wb_agent.req_ap.connect(self.ref_model.req_export)

class WbAdapterTest(uvm.uvm_test):
    def build_phase(self):
        #uvm.ConfigDB().is_tracing = True
        self.env = WbAdapterEnv.create("env", self)
    async def run_phase(self):
        self.raise_objection()
        seqr = uvm.ConfigDB().get(self, "env.bus_agent", "SEQR")
        seq = BusSeq("seq")
        await seq.start(seqr)
        self.drop_objection()
    def end_of_elaboration_phase(self):
        self.set_logging_level_hier(logging.DEBUG)
        self.set_logging_level_hier(uvm.FIFO_DEBUG)
        self.logger.debug("UVM hierarchy:")
        self.print_hierarchy(self.logger,self)
    @staticmethod        
    def print_hierarchy(logger: logging.Logger,component: uvm.uvm_component):
        child: uvm.uvm_component
        for child in component.children:
            if isinstance(child,uvm.uvm_export_base):
                continue
            logger.debug(f'{child.get_full_name()}')
            WbAdapterTest.print_hierarchy(logger,child)

