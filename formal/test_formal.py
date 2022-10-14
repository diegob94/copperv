from pathlib import Path

root_dir = Path(__file__).resolve().parent.parent

common_opts = dict(
    files = [root_dir/"rtl/uart/wb2uart.v",["formal/uart_tx.v",root_dir/"formal/uart_tx.v"]],
    engines = "smtbmc",
)

def test_uart_tx_bmc(sby_run):
    sby_run(
        **common_opts,
        options = ["mode bmc","depth 50"],
        script = ["read_verilog -formal wb2uart.v","prep -top uart_tx"],
    )

def test_uart_tx_prove(sby_run):
    sby_run(
        **common_opts,
        options = ["mode prove","depth 50"],
        script = ["read_verilog -formal wb2uart.v","prep -top uart_tx"],
    )

def test_uart_tx_cover(sby_run):
    sby_run(
        **common_opts,
        options = ["mode cover","depth 50"],
        script = ["read_verilog -formal -DCOVER_BASIC_TX=1 wb2uart.v","prep -top uart_tx"],
    )

