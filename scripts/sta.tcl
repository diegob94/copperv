set ROOT [exec readlink -f ../]
source ${ROOT}/scripts/fix_tcl_shell.tcl
source ${ROOT}/scripts/common_setup.tcl

set_cmd_units -time ns -capacitance pF -current mA -voltage V -resistance kOhm -distance um

read_liberty $LIB_FILE
read_verilog ${RESULTS_DIR}/copperv.synth.v
link_design $DESIGN_NAME 
