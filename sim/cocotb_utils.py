from collections import namedtuple
import subprocess

import cocotb
from cocotb.decorators import RunningTask
from cocotb.log import SimLog
from cocotb.triggers import RisingEdge, ReadOnly, NextTimeStep, FallingEdge
from cocotb.clock import Clock
from cocotb.types import Logic

from cocotb_bus.bus import Bus

import typing
import dataclasses

def get_top_module(name):
    return cocotb.handle.SimHandle(cocotb.simulator.get_root_handle(name))

def to_verilog_string(string):
    return int.from_bytes(string.encode("utf-8"),byteorder='big')

def from_array(data,addr):
    buf = []
    for i in range(4):
        value = 0
        if addr+i in data:
            value = data[addr+i]
        buf.append(value)
    return int.from_bytes(buf,byteorder='little')

def to_bytes(data):
    return (data).to_bytes(length=4,byteorder='little')

def run(*args,**kwargs):
    log = SimLog("cocotb")
    log.debug(f"run: {args}")
    r = subprocess.run(*args,shell=True,encoding='utf-8',capture_output=True,**kwargs)
    if r.returncode != 0:
        log.error(f"run stdout: {r.stdout}")
        log.error(f"run stderr: {r.stderr}")
        raise ChildProcessError(f"Error during command execution: {args}")
    return r
