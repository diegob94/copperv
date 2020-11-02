yosys echo on
set ROOT [file normalize ../]
set BLUESPECDIR $env(BLUESPECDIR)
set RTL_TOP $env(RTL_TOP)

set exclude_list {ResolveZ.v ProbeHook.v main.v ConvertFromZ.v ConvertToZ.v InoutConnect.v}
set BLUESPEC_LIBS [glob ${BLUESPECDIR}/Verilog/*.v]
foreach lib_file $BLUESPEC_LIBS {
    set skip false
    foreach exclude $exclude_list {
        if {[string first $exclude $lib_file] != -1} {
            puts "Info: Exclude read_verilog $lib_file"
            set skip true
        }
    }
    if { ! $skip } {
        yosys read_verilog -lib -defer $lib_file
    }
}

yosys hierarchy
yosys proc
yosys show $RTL_TOP

exit


#lmap LIB $LIB_FILES { read_liberty -lib -ignore_miss_func $LIB }
lmap RTL $RTL_FILES { read_verilog -I $INCLUDE_DIR $RTL }

#hierarchy -check -top $TOP_MODULE
synth -top $DESIGN_NAME
#share -aggressive
#opt
#opt_clean -purge
dfflibmap -liberty $LIB_FILE
abc -liberty $LIB_FILE
#hilomap -hicell sky130_fd_sc_hd__conb_1 HI -locell sky130_fd_sc_hd__conb_1 LO
#setundef -zero
#splitnets
#opt_clean -purge
insbuf -buf sky130_fd_sc_hd__buf_2 A X

write_verilog ${RESULTS_DIR}/copperv.synth.v
#yosys json -o synth.json
