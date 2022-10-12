
def test_uart_tx_bmc(sby_run):
    sby_run(
        options = ["mode bmc","depth 50"],
        engines = "smtbmc",
        script = ["read_verilog -formal wb2uart.v","prep -top uart_tx"],
        files = ["../rtl/uart/wb2uart.v","formal/uart_tx.v uart_tx.v"],
    )

def test_uart_tx_prove(sby_run):
    sby_run(
        options = ["mode prove","depth 50"],
        engines = "smtbmc",
        script = ["read_verilog -formal wb2uart.v","prep -top uart_tx"],
        files = ["../rtl/uart/wb2uart.v","formal/uart_tx.v uart_tx.v"],
    )

def test_uart_tx_cover(sby_run):
    sby_run(
        options = ["mode cover","depth 50"],
        engines = "smtbmc",
        script = ["read_verilog -formal -DCOVER_BASIC_TX=1 wb2uart.v","prep -top uart_tx"],
        files = ["../rtl/uart/wb2uart.v","formal/uart_tx.v uart_tx.v"],
    )

