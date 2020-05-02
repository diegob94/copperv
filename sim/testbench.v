`timescale 1ns/1ps
`include "testbench_h.v"
`include "copperv_h.v"

module tb();
parameter bus_width = 32;
parameter timeout = `PERIOD*50;
reg clk;
reg rst;
wire d_rdata_valid;
wire d_raddr_ready;
wire d_wdata_ready;
wire d_waddr_ready;
wire [bus_width-1:0] d_rdata;
wire i_rdata_valid;
wire i_raddr_ready;
wire i_wdata_ready;
wire i_waddr_ready;
wire [bus_width-1:0] i_rdata;
wire d_rdata_ready;
wire d_raddr_valid;
wire d_wdata_valid;
wire d_waddr_valid;
wire [bus_width-1:0] d_raddr;
wire [bus_width-1:0] d_wdata;
wire [bus_width-1:0] d_waddr;
wire i_rdata_ready;
wire i_raddr_valid;
wire i_wdata_valid;
wire i_waddr_valid;
wire [bus_width-1:0] i_raddr;
wire [bus_width-1:0] i_wdata;
wire [bus_width-1:0] i_waddr;
initial begin
    rst = 0;
    clk = 0;
    #(`PERIOD*10);
    $display($time, ": Reset finished");
    rst = 1;
end
initial begin
    #timeout;
    $display($time, ": Failed: Timeout");
    finish_sim;
end
always #(`PERIOD/2) clk <= !clk;
copperv dut(
    .clk(clk),
    .rst(rst),
    .d_rdata_valid(d_rdata_valid),
    .d_raddr_ready(d_raddr_ready),
    .d_wdata_ready(d_wdata_ready),
    .d_waddr_ready(d_waddr_ready),
    .d_rdata(d_rdata),
    .i_rdata_valid(i_rdata_valid),
    .i_raddr_ready(i_raddr_ready),
    .i_wdata_ready(i_wdata_ready),
    .i_waddr_ready(i_waddr_ready),
    .i_rdata(i_rdata),
    .d_rdata_ready(d_rdata_ready),
    .d_raddr_valid(d_raddr_valid),
    .d_wdata_valid(d_wdata_valid),
    .d_waddr_valid(d_waddr_valid),
    .d_raddr(d_raddr),
    .d_wdata(d_wdata),
    .d_waddr(d_waddr),
    .i_rdata_ready(i_rdata_ready),
    .i_raddr_valid(i_raddr_valid),
    .i_wdata_valid(i_wdata_valid),
    .i_waddr_valid(i_waddr_valid),
    .i_raddr(i_raddr),
    .i_wdata(i_wdata),
    .i_waddr(i_waddr)
);
native_memory #(.instruction_memory(`TRUE)) i_mem(
    .clk(clk),
    .rst(rst),
    .rdata_valid(i_rdata_valid),
    .raddr_ready(i_raddr_ready),
    .wdata_ready(i_wdata_ready),
    .waddr_ready(i_waddr_ready),
    .rdata(i_rdata),
    .rdata_ready(i_rdata_ready),
    .raddr_valid(i_raddr_valid),
    .wdata_valid(i_wdata_valid),
    .waddr_valid(i_waddr_valid),
    .raddr(i_raddr),
    .wdata(i_wdata),
    .waddr(i_waddr)
);
native_memory d_mem(
    .clk(clk),
    .rst(rst),
    .rdata_valid(d_rdata_valid),
    .raddr_ready(d_raddr_ready),
    .wdata_ready(d_wdata_ready),
    .waddr_ready(d_waddr_ready),
    .rdata(d_rdata),
    .rdata_ready(d_rdata_ready),
    .raddr_valid(d_raddr_valid),
    .wdata_valid(d_wdata_valid),
    .waddr_valid(d_waddr_valid),
    .raddr(d_raddr),
    .wdata(d_wdata),
    .waddr(d_waddr)
);
monitor_cpu mon(
    .clk(clk),
    .rst(rst)
);
checker_cpu chk(
    .clk(clk),
    .rst(rst)
);

initial begin
    $dumpfile("tb.lxt");
    $dumpvars(0, tb);
end

task finish_sim;
integer i;
begin
    $display($time, ": REGFILE DUMP BEGIN");
    for(i = 0; i < 32; i = i + 1) begin
        $display($time, ": 0x%02X: 0x%08X", i, `CPU_INST.regfile.memory[i]);
    end
    $display($time, ": REGFILE DUMP END");
    $finish;
end
endtask
endmodule

