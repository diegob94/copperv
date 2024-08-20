interface idecoder_bfm;

  parameter name = "X";

  import copperv_pkg::*;

  inst_td inst;
  decoded_inst_s decoded_inst;

  task display();
    $display("%t: %m: inst='h%0x decoded=%p",$time,inst,decoded_inst);
  endtask : display

endinterface : idecoder_bfm
