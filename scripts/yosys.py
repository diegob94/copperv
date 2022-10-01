#!/usr/bin/python3

import os
import subprocess
from pyosys import libyosys as ys

default_run_opts = dict(
    shell=True,
    check=False,
    encoding='utf-8',
    env = os.environ,
)

def run(c,run_opts=default_run_opts):
    print(c)
    subprocess.run(c,**run_opts)

root = '..'
design = ys.Design()

ys.run_pass(f"verilog_defaults -add -I{root}/src/main/resources/rtl_v1/include",design)
ys.run_pass(f"read_verilog {root}/work/chisel/copperv2.v",design)
ys.run_pass(f"read_verilog {root}/src/main/resources/rtl_v1/execution.v",design)
ys.run_pass(f"read_verilog {root}/src/main/resources/rtl_v1/register_file.v",design)
ys.run_pass(f"read_verilog {root}/src/main/resources/rtl_v1/idecoder.v",design)

ys.run_pass(f"prep -auto-top", design)

ys.run_pass("select -module Copperv2Core c:$*",design)
ys.run_pass("submod -name bus_if",design)
ys.run_pass("cd", design)

modules = [module.name.str().lstrip('\\') for module in design.selected_whole_modules_warn()]
ys.run_pass(f"design -save top", design)

for module in modules:
    json = f"{root}/work/{module}.json"
    ys.run_pass(f"hierarchy -top {module}", design)
    ys.run_pass(f"write_json {json}", design)
    ys.run_pass("design -load top", design)
    run(f"netlistsvg {json} -o {root}/work/{module}.svg")

print("Done")
