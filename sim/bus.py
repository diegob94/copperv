import dataclasses
import typing

import cocotb
from cocotb.triggers import RisingEdge, ReadOnly, NextTimeStep, Combine, Event
from cocotb_bus.monitors import Monitor, BusMonitor
from cocotb_bus.drivers import Driver
from cocotb.log import SimLog
from cocotb.queue import Queue
from cocotb.types import Logic
from cocotb_bus.bus import Bus

@dataclasses.dataclass
class BusReadTransaction:
    bus_name: str
    data: int = None
    addr: int = None
    @classmethod
    def from_string(cls, string):
        addr, data = string.split()
        return cls(
            bus_name=None,
            data=int(data,0),
            addr=int(addr,0))
    @classmethod
    def from_reqresp(cls, bus_name, request, response = None):
        new = cls(bus_name=bus_name,addr=request['addr'])
        if response is not None:
            new.data = response['data']
        return new
    def to_reqresp(self):
        return dict(request = dict(addr=self.addr), response = dict(data=self.data))
    def add_response(self,response):
        self.data = response['data']
    @classmethod
    def default_transaction(cls,bus_name):
        return cls(bus_name=bus_name,addr=0,data=0)
    def __eq__(self, other) -> bool:
        return self.addr == other.addr and self.data == other.data
    def __str__(self):
        data = f'0x{self.data:X}' if self.data is not None else None
        addr = f'0x{self.addr:X}' if self.addr is not None else None
        return f'{self.__class__.__name__}(bus_name={self.bus_name}, addr={addr}, data={data})'


@dataclasses.dataclass
class BusWriteTransaction:
    bus_name: str
    data: int = None
    addr: int = None
    strobe: int = None
    response: int = None
    @classmethod
    def from_string(cls, string):
        addr, data, strobe, response = string.split()
        return cls(
            bus_name=None,
            data=int(data,0),
            addr=int(addr,0),
            strobe=int(strobe,0),
            response=int(response,0))
    @classmethod
    def from_reqresp(cls, bus_name, request, response = None):
        new = cls(
            bus_name = bus_name,
            data = request['data'],
            addr = request['addr'],
            strobe = request['strobe'])
        if response is not None:
            new.response = response['resp']
        return new
    def to_reqresp(self):
        return dict(
                request = dict(data=self.data,addr=self.addr,strobe=self.strobe),
                response = dict(resp=self.response)
            )
    def add_response(self,response):
        self.response = response['resp']
    @classmethod
    def default_transaction(cls,bus_name):
        return cls(bus_name=bus_name,addr=0,data=0,strobe=0,response=0)
    def __eq__(self, other) -> bool:
        return self.addr == other.addr and self.data == other.data \
            and self.strobe == other.strobe and self.response == other.response
    def __str__(self):
        data = f'0x{self.data:X}' if self.data is not None else None
        addr = f'0x{self.addr:X}' if self.addr is not None else None
        strobe = f'0x{self.strobe:X}' if self.strobe is not None else None
        response = f'0x{self.response:X}' if self.response is not None else None
        return f'{self.__class__.__name__}(bus_name={self.bus_name}, addr={addr}, data={data}, strobe={strobe}, response={response})'

class CoppervBusChannel:
    def __init__(self,clock,ready,valid,payload,bus,reset=None,reset_n=None,relaxed_mode=False):
        self.log = SimLog(f"cocotb.{type(self).__qualname__}")
        self.payload = {k:getattr(bus,v) for k,v in payload.items()}
        self.ready = getattr(bus,ready)
        self.valid = getattr(bus,valid)
        self.queue = Queue()
        self.relaxed_mode = relaxed_mode
        self._reset = reset
        self._reset_n = reset_n
        self.clock = clock
    def init_sink(self):
        self.ready.setimmediatevalue(1)
        cocotb.start_soon(self.recv_payload())
    def init_source(self):
        self.valid.setimmediatevalue(0)
        cocotb.start_soon(self.recv_payload())
    def to_int(self,value):
        if self.relaxed_mode:
            return int(value.binstr.replace('x','0'),2)
        else:
            return int(value)
    @property
    def in_reset(self):
        """Boolean flag showing whether the bus is in reset state or not."""
        if self._reset is not None:
            # self.log.debug(f"[{self.__class__.__qualname__}] in_reset: {self._reset._name}")
            return bool(self._reset.value.integer)
        if self._reset_n is not None:
            # self.log.debug(f"[{self.__class__.__qualname__}] in_reset: {self._reset_n._name}")
            return not bool(self._reset_n.value.integer)
        return False
    async def wait_for_signal(self,signal,value):
        self.log.debug(f"wait_for_signal: {signal._name} value {value}")
        await ReadOnly()
        while self.in_reset or Logic(signal.value.binstr) != Logic(value):
            await RisingEdge(self.clock)
            await ReadOnly()
        self.log.debug(f"wait_for_signal: {signal._name} value {value} return")
        await NextTimeStep()
    async def recv_payload(self):
        while(True):
            await RisingEdge(self.clock)
            await ReadOnly()
            if self.in_reset:
                self.log.debug(f"recv_payload in_reset true, continue")
                continue
            if self.ready.value and self.valid.value:
                actual_payload = {k:self.to_int(p.value) for k,p in self.payload.items()}
                self.log.debug(f"Receiving payload: {actual_payload}")
                self.queue.put_nowait(actual_payload)
    async def send_payload(self,**kwargs):
        self.log.debug(f"Send payload: {kwargs}")
        await self.wait_for_signal(self.ready,1)
        self.valid.value = 1
        for name,payload_signal in self.payload.items():
            payload_signal.value = int(kwargs[name])
        await RisingEdge(self.clock)
        await NextTimeStep()
        self.valid.value = 0
    async def drive_ready(self,value):
        self.log.debug(f"Drive ready: {value}")
        await RisingEdge(self.clock)
        self.ready.value = value
    async def drive_valid(self,value):
        self.log.debug(f"Drive valid: {value}")
        await RisingEdge(self.clock)
        self.valid.value = value

class CoppervBusMonitor(Monitor):
    _signals = []
    def __init__(self, entity, name, clock, transaction_type, bus_name,
            req_ch, resp_ch, signals_dict=None, resp_gen=None, reset=None,
            reset_n=None, callback=None, event=None, **kwargs):
        self.entity = entity
        self.name = name
        self.clock = clock
        self.transaction_type = transaction_type
        self.bus_name = bus_name
        if signals_dict is not None:
            self._signals = signals_dict
        self.bus = Bus(self.entity, self.name, self._signals)
        self.req_ch = CoppervBusChannel(self.clock,bus=self.bus,**req_ch)
        self.resp_ch = CoppervBusChannel(self.clock,bus=self.bus,**resp_ch)
        self.resp_gen = resp_gen
        if self.resp_gen is None:
            self.resp_gen = lambda x: {k:0 for k in self.resp_ch.payload}
        self.req_ch.init_sink()
        self.resp_ch.init_source()
        super().__init__(callback=callback,event=event)
    async def _monitor_recv(self):
        while True:
            req_payload = await self.req_ch.queue.get()
            req_transaction = self.transaction_type.from_reqresp(bus_name=self.bus_name,request=req_payload)
            resp_transaction = self.resp_gen(req_transaction)
            if isinstance(resp_transaction, self.transaction_type):
                temp = self.transaction_type.to_reqresp(resp_transaction)
                self.log.debug("responding read transaction: %s", temp)
                await self.resp_ch.send_payload(**temp['response'])
            elif resp_transaction == "assert_ready":
                await self.resp_ch.drive_ready(True)
            elif resp_transaction == "deassert_ready":
                await self.resp_ch.drive_ready(False)
            resp_payload = await self.resp_ch.queue.get()
            transaction = self.transaction_type.from_reqresp(
                bus_name = self.bus_name,
                request = req_payload,
                response = resp_payload
            )
            self._recv(transaction)

class CoppervBusIrMonitor(CoppervBusMonitor):
    _signals = [
        "ir_addr_valid", "ir_addr_ready", "ir_addr",
        "ir_data_valid", "ir_data_ready", "ir_data",
    ]
    def __init__(self, entity, prefix, clock, signals_dict=None, resp_gen=None, **kwargs):
        super().__init__(entity,prefix,clock,BusReadTransaction,"bus_ir",
            signals_dict=signals_dict,
            resp_gen=resp_gen,
            req_ch = dict(ready="ir_addr_ready",valid="ir_addr_valid",payload=dict(addr="ir_addr")),
            resp_ch = dict(ready="ir_data_ready",valid="ir_data_valid",payload=dict(data="ir_data")),
            **kwargs)

class CoppervBusDrMonitor(CoppervBusMonitor):
    _signals = [
        "dr_addr_valid", "dr_addr_ready", "dr_addr",
        "dr_data_valid", "dr_data_ready", "dr_data",
    ]
    def __init__(self, entity, prefix, clock, signals_dict=None, resp_gen=None, **kwargs):
        super().__init__(entity,prefix,clock,BusReadTransaction,"bus_dr",
            signals_dict=signals_dict,
            resp_gen=resp_gen,
            req_ch = dict(ready="dr_addr_ready",valid="dr_addr_valid",payload=dict(addr="dr_addr")),
            resp_ch = dict(ready="dr_data_ready",valid="dr_data_valid",payload=dict(data="dr_data")),
            **kwargs)

class CoppervBusDwMonitor(CoppervBusMonitor):
    _signals = [
        "dw_data_addr_ready", "dw_data_addr_valid", 
        "dw_data", "dw_addr", "dw_strobe",
        "dw_resp_ready", "dw_resp_valid", "dw_resp",
    ]
    def __init__(self, entity, prefix, clock, signals_dict=None, resp_gen=None, **kwargs):
        super().__init__(entity,prefix,clock,BusWriteTransaction,"bus_dw",
            signals_dict=signals_dict,
            resp_gen=resp_gen,
            req_ch = dict(ready="dw_data_addr_ready",valid="dw_data_addr_valid",payload=dict(addr="dw_addr",data="dw_data",strobe="dw_strobe")),
            resp_ch = dict(ready="dw_resp_ready",valid="dw_resp_valid",payload=dict(resp="dw_resp")),
            **kwargs)

class CoppervBusDriver(Driver):
    _signals = []
    def __init__(self, entity, name, clock, transaction_type, bus_name,
            req_ch, resp_ch, signals_dict=None, resp_gen=None, reset=None,
            reset_n=None, callback=None, event=None, **kwargs):
        self.entity = entity
        self.name = name
        self.clock = clock
        self.transaction_type = transaction_type
        self.bus_name = bus_name
        if signals_dict is not None:
            self._signals = signals_dict
        self.bus = Bus(self.entity, self.name, self._signals)
        self.req_ch = CoppervBusChannel(self.clock,bus=self.bus,**req_ch)
        self.resp_ch = CoppervBusChannel(self.clock,bus=self.bus,**resp_ch)
        self.req_ch.init_source()
        self.resp_ch.init_sink()
        super().__init__()
    async def _driver_send(self, transaction, sync: bool = True):
        temp = self.transaction_type.to_reqresp(transaction)
        self.log.debug("Send transaction: %s", temp)
        await self.req_ch.send_payload(**temp['request'])
        response = await self.resp_ch.queue.get()
        transaction.add_response(response)

class CoppervBusRDriver(CoppervBusDriver):
    _signals = [
        "r_addr_ready", "r_addr_valid", "r_addr_bits",
        "r_data_ready", "r_data_valid", "r_data_bits",
    ]
    def __init__(self, entity, prefix, clock, signals_dict=None, **kwargs):
        super().__init__(entity,prefix,clock,BusReadTransaction,"bus_r",
            signals_dict=signals_dict,
            req_ch = dict(ready="r_addr_ready",valid="r_addr_valid",payload=dict(addr="r_addr_bits")),
            resp_ch = dict(ready="r_data_ready",valid="r_data_valid",payload=dict(data="r_data_bits")),
            **kwargs)

class CoppervBusWDriver(CoppervBusDriver):
    _signals = [
        "w_req_ready",  "w_req_valid",  "w_req_bits_data",
        "w_req_bits_addr", "w_req_bits_strobe",
        "w_resp_ready", "w_resp_valid", "w_resp_bits",
    ]
    def __init__(self, entity, prefix, clock, signals_dict=None, **kwargs):
        super().__init__(entity,prefix,clock,BusWriteTransaction,"bus_w",
            signals_dict=signals_dict,
            req_ch = dict(ready="w_req_ready",valid="w_req_valid",
                payload=dict(addr="w_req_bits_addr",data="w_req_bits_data",strobe="w_req_bits_strobe")),
            resp_ch = dict(ready="w_resp_ready",valid="w_resp_valid",payload=dict(resp="w_resp_bits")),
            **kwargs)

