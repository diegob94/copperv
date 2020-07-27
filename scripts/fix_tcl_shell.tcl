
if {$tcl_interactive} {
#    package require tclreadline 
    set SAVE_CWD [pwd]
    set LIB_TCLREADLINE /usr/lib64/tcl8.6/tclreadline2.1.0
    cd $LIB_TCLREADLINE
    uplevel #0 source tclreadlineInit.tcl
    cd $SAVE_CWD
    unset SAVE_CWD
    namespace eval tclreadline { 
         proc prompt1 {} { 
             return "[file tail [info nameofexecutable]]> "
         } 
    }
    ::tclreadline::Loop
}
