set ROOT [exec readlink -f ../]
set RTL_FILES [glob -directory $ROOT/rtl/ *.v]
set INCLUDE_DIR $ROOT/rtl/include

# read design 
foreach RTL_FILE $RTL_FILES {
#    puts "Reading Verilog: $RTL_FILE"
    yosys read_verilog -I$INCLUDE_DIR $RTL_FILE
}
#yosys proc
#yosys check
#yosys write_verilog rtl.v
#yosys json -o rtl.json
#yosys write_firrtl rtl.fir
#puts exit

# generic synthesis
yosys synth -top copperv

yosys scc
exit

# mapping to mycells.lib
#yosys dfflibmap -liberty mycells.lib
#yosys abc -liberty mycells.lib
#yosys clean

# write synthesized design
yosys write_verilog synth.v
yosys json -o synth.json
