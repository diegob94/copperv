from pathlib import Path

root_dir = Path(__file__).resolve().parent.parent

common_opts = dict(
    engines = "smtbmc",
)

uart_tx_files = [root_dir/"rtl/uart/wb2uart.v",["formal/uart_tx.v",root_dir/"formal/uart_tx.v"]]
def test_uart_tx_bmc(sby_run):
    sby_run(
        **common_opts,
        options = ["mode bmc","depth 50"],
        script = ["read_verilog -formal wb2uart.v","prep -top uart_tx"],
        files = uart_tx_files,
    )

def test_uart_tx_prove(sby_run):
    sby_run(
        **common_opts,
        options = ["mode prove","depth 50"],
        script = ["read_verilog -formal wb2uart.v","prep -top uart_tx"],
        files = uart_tx_files,
    )

def test_uart_tx_cover(sby_run):
    sby_run(
        **common_opts,
        options = ["mode cover","depth 50"],
        script = ["read_verilog -formal -DCOVER_BASIC_TX=1 wb2uart.v","prep -top uart_tx"],
        files = uart_tx_files,
    )

sram_script = ["read_verilog -formal sram_32_sp.v","prep -top sram_32_sp"]
sram_files = [root_dir/"rtl/memory/sram_32_sp.v", ["formal/sram_32_sp.v",root_dir/"formal/sram_32_sp.v"]]
def test_sram_bmc(sby_run):
    sby_run(
        **common_opts,
        options = ["mode bmc","depth 10"],
        script = sram_script,
        files = sram_files,
    )

def test_uart_tx_prove(sby_run):
    sby_run(
        **common_opts,
        options = ["mode prove","depth 10"],
        script = sram_script,
        files = sram_files,
    )

wb_sram_script = [
    "read_verilog -formal wb_sram.v",
    "read_verilog -formal sram_1r1w.v",
    "read_verilog -formal fwb_slave.v",
    "prep -top wb_sram"
]
wb_sram_files = sram_files + [
    root_dir/"rtl/wishbone/wb_sram.v",
    root_dir/"external_ip/wb2axip/bench/formal/fwb_slave.v",
    ["formal/wb_sram.v", root_dir/"formal/wb_sram.v"],
]
def test_wb_sram_bmc(sby_run):
    sby_run(
        **common_opts,
        options = ["mode bmc","depth 10","append 2"],
        script = wb_sram_script,
        files = wb_sram_files,
    )

def test_wb_sram_prove(sby_run):
    sby_run(
        **common_opts,
        options = ["mode prove","depth 10"],
        script = wb_sram_script,
        files = wb_sram_files,
    )

def add_option(line,option):
    r = []
    for i,tok in enumerate(line.split()):
        if i == 0:
            r.append(tok)
            r.append(option)
            continue
        r.append(tok)
    return " ".join(r)

def test_wb_sram_cover(sby_run):
    sby_run(
        **common_opts,
        options = ["mode cover","depth 10","append 2"],
        script = [line if not "read_verilog" in line else add_option(line,"-DCOVER_WB_SRAM=1") for line in wb_sram_script],
        files = wb_sram_files,
    )
