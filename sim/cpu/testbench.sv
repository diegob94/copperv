module testbench();
  import copperv_params_pkg::*;

  reg clk;
  always #10 clk = ~clk;
  reg rst;

  wishbone_if #(
    .dat_width(data_width),
    .adr_width(bus_width),
    .sel_width(4)
  ) data_if();
  wishbone_if #(
    .dat_width(inst_width),
    .adr_width(pc_width),
    .sel_width(4)
  ) inst_if();
  wishbone_bfm data_bfm(
    .clk(clk),
    .rst(rst),
    .vif(data_if.master)
  );
  wishbone_bfm inst_bfm(
    .clk(clk),
    .rst(rst),
    .vif(inst_if.master)
  );
  copperv dut(.*);
  idecoder_bfm idec_bfm();
  assign idec_bfm.inst = dut.idec.inst;
  assign idec_bfm.decoded_inst = dut.idec.decoded_inst;

  int read_adr = 0;

  initial begin
    $dumpfile("testbench.vcd");
    $dumpvars;
    clk = 0;
    rst = 1;
    repeat (5) @(posedge clk);
    rst = 0;
    inst_bfm.wait_read_adr(read_adr);
    inst_bfm.send_read_dat(read_adr + 1);
    repeat (100) @(posedge clk);
    $finish;
  end

  always @(posedge clk)
    if (dut.inst_valid)
      idec_bfm.display();

  initial begin
    repeat (1000) @(posedge clk);
    $display("Timeout!");
    $finish;
  end

endmodule
