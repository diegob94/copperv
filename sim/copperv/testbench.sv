import wishbone_pkg::*;

module testbench();
  reg clk;
  always #10 clk = ~clk;
  reg rst;

  wishbone_if data_if;
  wishbone_if inst_if;
  copperv dut(clk,rst,data_if,inst_if);

  initial begin
    clk <= 0;
    rst <= 1;
    repeat (5) @(posedge clk);
    rst <= 0;
    repeat (2) @(posedge clk);
    $finish;
  end
endmodule
