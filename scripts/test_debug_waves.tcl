puts "START_SCRIPT: [info script]"

proc add_signal { signal {mapping {}} } {
    gtkwave::addSignalsFromList "$signal"
    if {[llength $mapping] != 0} {
        if {![info exists ::mapping_table]} {
            set ::mapping_table {}
        }
        if {![dict exists $::mapping_table $mapping]} {
            set enum {}
            dict for {k v} $mapping {
                lappend enum $v $k
            }
            set mapping_file [gtkwave::setCurrentTranslateEnums $enum]
            dict set ::mapping_table $mapping $mapping_file
        }
        gtkwave::highlightSignalsFromList "$signal"
        gtkwave::/Edit/Data_Format/Decimal
        gtkwave::installFileFilter [dict get $::mapping_table $mapping]
        gtkwave::/Edit/UnHighlight_All
    }
}

proc zoom_all {} {
    gtkwave::/Time/Zoom/Zoom_Full
}

set state_enum {}
dict set state_enum RESET  0
dict set state_enum IDLE   1
dict set state_enum FETCH  2
dict set state_enum DECODE 3
dict set state_enum EXEC   4
dict set state_enum MEM    5
dict set state_enum COMMIT 6

add_signal copperv2.core.pc
add_signal copperv2.core.control.state $state_enum
add_signal copperv2.core.alu.in1
add_signal copperv2.core.alu.in2
add_signal copperv2.core.alu.io_load
add_signal copperv2.core.regfile.rd
add_signal copperv2.core.regfile.rd_en
add_signal copperv2.core.regfile.rd_din
add_signal copperv2.core.regfile.rs1
add_signal copperv2.core.regfile.rs1_en
add_signal copperv2.core.regfile.rs1_dout
add_signal copperv2.core.regfile.rs2
add_signal copperv2.core.regfile.rs2_en
add_signal copperv2.core.regfile.rs2_dout

zoom_all

puts "mapping_table: $::mapping_table"

puts "END_SCRIPT: [info script]"