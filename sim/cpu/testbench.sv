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

  int read_adr = 0;

  always @(posedge clk) begin
    if (dut.regfile.rd_en)
      $display("%t: %m: regfile write: rd['h%0x]='h%0x",$time,dut.regfile.rd,dut.regfile.rd_din);
    if (dut.regfile.rs1_en)
      $display("%t: %m: regfile read: rs1['h%0x]='h%0x",$time,dut.regfile.rs1,dut.regfile.rs1_dout);
    if (dut.regfile.rs2_en)
      $display("%t: %m: regfile read: rs2['h%0x]='h%0x",$time,dut.regfile.rs2,dut.regfile.rs2_dout);
    if (dut.control.state == dut.control.state_exec)
      $display("%t: %m: alu execution: din1='h%0x din2='h%0x op='h%0x dout='h%0x comp=%p",$time,dut.alu.alu_din1,dut.alu.alu_din2,dut.alu.alu_op,dut.alu.alu_dout,dut.alu.alu_comp);
    if (dut.inst_valid)
      $display("%t: %m: idecode: inst='h%0x decoded=%p",$time,dut.idec.inst,dut.idec.decoded_inst);
    if (!rst && dut.control.state_change_next)
      $display("%t: %m: control state: %s",$time,dut.control.state.name());
  end

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

  initial begin
    repeat (1000) @(posedge clk);
    $display("Timeout!");
    $finish;
  end

endmodule
