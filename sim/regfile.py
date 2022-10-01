import dataclasses

import cocotb
from cocotb.triggers import RisingEdge, ReadOnly, Combine
from cocotb_bus.monitors import Monitor
from cocotb.log import SimLog

from riscv_constants import abi_reg_map, reg_abi_map
from cocotb_bus.monitors import BusMonitor

@dataclasses.dataclass
class RegFileWriteTransaction:
    reg: int = None
    data: int = None
    @property
    def reg_name(self):
        if self.reg is None:
            return None
        return reg_abi_map[self.reg] 
    @classmethod
    def from_string(cls, string):
        tokens = string.split()
        reg, value = tokens
        return cls(abi_reg_map[reg],int(value,0))
    def __str__(self):
        data = f'0x{self.data:X}' if self.data is not None else None
        return f'RegFileWriteTransaction(reg={self.reg_name}, data={data})'

@dataclasses.dataclass
class RegFileReadTransaction:
    reg1: int = None
    data1: int = None
    reg2: int = None
    data2: int = None
    @classmethod
    def from_string(cls, string):
        tokens = string.split()
        if len(tokens) == 2:
            reg, value = tokens
            return cls(abi_reg_map[reg],int(value,0))
        elif len(tokens) == 4:
            reg1, value1, reg2, value2 = tokens
            return cls(abi_reg_map[reg1],int(value1,0)
                    ,abi_reg_map[reg2],int(value2,0))
        else:
            ValueError("Invalid transaction")
    @property
    def reg1_name(self):
        if self.reg1 is None:
            return None
        return reg_abi_map[self.reg1]
    @property
    def reg2_name(self):
        if self.reg2 is None:
            return None
        return reg_abi_map[self.reg2]
    def __str__(self):
        data1 = f'0x{self.data1:X}' if self.data1 is not None else None
        data2 = f'0x{self.data2:X}' if self.data2 is not None else None
        return f'RegFileReadTransaction(reg1={self.reg1_name}, data1={data1}, reg2={self.reg2_name}, data1={data2})'

class RegFileWriteMonitor(BusMonitor):
    _signals = [
        "rd_en",
        "rd_addr",
        "rd_data",
    ]
    def __init__(self, entity, prefix, clock, signals_dict=None, **kwargs):
        if signals_dict is not None:
            self._signals = signals_dict
        super().__init__(entity,prefix,clock,**kwargs)
    async def _monitor_recv(self):
        while True:
            await RisingEdge(self.clock)
            await ReadOnly()
            if self.bus.rd_en.value:
                transaction = RegFileWriteTransaction(
                    reg = int(self.bus.rd_addr.value),
                    data = int(self.bus.rd_data.value),
                )
                self.log.debug("Regfile write: %s", transaction)
                self._recv(transaction)

class RegFileReadMonitor(BusMonitor):
    _signals = [
        "rs1_en",
        "rs1_addr",
        "rs1_data",
        "rs2_en",
        "rs2_addr",
        "rs2_data",
    ]
    def __init__(self, entity, prefix, clock, signals_dict=None, **kwargs):
        if signals_dict is not None:
            self._signals = signals_dict
        super().__init__(entity,prefix,clock,**kwargs)
    async def _monitor_recv(self):
        while True:
            transaction = None
            await RisingEdge(self.clock)
            await ReadOnly()
            en1 = self.bus.rs1_en.value
            en2 = self.bus.rs2_en.value
            if en1 or en2:
                await RisingEdge(self.clock)
                await ReadOnly()
                if en1 and en2:
                    transaction = RegFileReadTransaction(
                        reg1 = int(self.bus.rs1_addr.value),
                        data1 = int(self.bus.rs1_data.value),
                        reg2 = int(self.bus.rs2_addr.value),
                        data2 = int(self.bus.rs2_data.value),
                    )
                elif en1:
                    transaction = RegFileReadTransaction(
                        reg1 = int(self.bus.rs1_addr.value),
                        data1 = int(self.bus.rs1_data.value),
                    )
                elif en2:
                    transaction = RegFileReadTransaction(
                        reg1 = int(self.bus.rs2_addr.value),
                        data1 = int(self.bus.rs2_data.value),
                    )
                self.log.debug('Regfile read: %s',transaction)
                self._recv(transaction)

