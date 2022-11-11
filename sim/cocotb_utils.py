from collections import namedtuple
from pathlib import Path
import toml
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
    r = subprocess.run(*args,shell=True,encoding='utf-8',capture_output=True,text=True,**kwargs)
    if r.returncode != 0:
        log.error(f"run stdout: {r.stdout}")
        log.error(f"run stderr: {r.stderr}")
        raise ChildProcessError(f"Error during command execution: {args}")
    return r.stdout.strip()

root_dir = Path(__file__).resolve().parent.parent
sim_dir = root_dir/'sim'
magic_constants = toml.load(sim_dir/"magic_constants.toml")
APP_START_ADDR = magic_constants["APP_START_ADDR"]
BOOTLOADER_MAGIC_ADDR = magic_constants["BOOTLOADER_MAGIC_ADDR"]
T_ADDR = magic_constants["T_ADDR"]
O_ADDR = magic_constants["O_ADDR"]
TC_ADDR = magic_constants["TC_ADDR"]
T_PASS = magic_constants["T_PASS"]
T_FAIL = magic_constants["T_FAIL"]

