module testbench();
  reg clk;
  always #10 clk = ~clk;
  reg rst;

  wishbone_if data_if();
  wishbone_if inst_if();
  wishbone_bfm data_bfm(.*);
  wishbone_bfm inst_bfm(.*);
  copperv dut(.*);

  assign data_if.ack = data_bfm.ack;
  assign data_if.datrd = data_bfm.datrd;
  assign data_bfm.adr = data_if.adr;
  assign data_bfm.datwr = data_if.datwr;
  assign data_bfm.we = data_if.we;
  assign data_bfm.stb = data_if.stb;
  assign data_bfm.cyc = data_if.cyc;
  assign data_bfm.sel = data_if.sel;
  assign inst_if.ack = inst_bfm.ack;
  assign inst_if.datrd = inst_bfm.datrd;
  assign inst_bfm.adr = inst_if.adr;
  assign inst_bfm.datwr = inst_if.datwr;
  assign inst_bfm.we = inst_if.we;
  assign inst_bfm.stb = inst_if.stb;
  assign inst_bfm.cyc = inst_if.cyc;
  assign inst_bfm.sel = inst_if.sel;

  int read_adr = 0;

  initial begin
    $dumpfile("testbench.vcd");
    $dumpvars;
  end

  initial begin
    clk = 0;
    rst = 1;
    repeat (5) @(posedge clk);
    rst = 0;
    inst_bfm.wait_read_adr(read_adr);
    inst_bfm.send_read_dat(read_adr + 1);
    repeat (100) @(posedge clk);
    $finish;
  end

  initial begin
    repeat (1000) @(posedge clk);
    $display("Timeout!");
    $finish;
  end

endmodule
