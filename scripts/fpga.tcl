yosys echo on

source scripts/rtl_sources.tcl
set COPPERV_INCLUDES [lindex $COPPERV_INCLUDES 0]

foreach RTL_FILE $TOP_RTL {
    yosys read_verilog -I$COPPERV_INCLUDES $RTL_FILE
}

yosys synth_ecp5 -noccu2

yosys write_verilog -noattr work/top.yosys.v 
yosys write_json work/top.json
