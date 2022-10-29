yosys echo on

set RTL_SOURCES {
    rtl/copperv/control_unit.v
    rtl/copperv/copperv.v
    rtl/copperv/execution.v
    rtl/copperv/idecoder.v
    rtl/copperv/register_file.v
    rtl/include/copperv_h.v
    rtl/memory/sram_32_sp.v
    rtl/top.sv
    rtl/uart/wb2uart.sv
    rtl/wishbone/wb_adapter.v
    rtl/wishbone/wb_copperv.sv
    rtl/wishbone/wb_sram.v
    rtl/wishbone/wb_xbar.sv
    rtl/wishbone/wishbone_bus_if.sv
}

file mkdir work
yosys exec -- sv2v -w work/top.sv2v.v -I./rtl/include [concat {*}$RTL_SOURCES]

yosys read_verilog work/top.sv2v.v

## no support for interface_array (29/10/22)
#yosys plugin -i systemverilog
#yosys read_systemverilog -debug {*}[concat {*}$RTL_SOURCES]

yosys synth_ecp5 ;#-noccu2 -nomux -nodram

yosys write_verilog -noattr work/top.yosys.v 
yosys write_json work/top.json
