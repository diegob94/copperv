`timescale 1ns/1ps

`define STRING reg [1023:0]
`define PERIOD 10
`define TRUE 1
`define FALSE 0

module tb();
parameter bus_width = 32;
parameter timeout = 100000;
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
    rst = 1;
    clk = 0;
    #(`PERIOD*100);
    rst = 0;
end
initial begin
    #timeout;
    $display("%t: Failed: Timeout", $time);
    $finish;
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
endmodule

module native_memory #(
    parameter address_width = 8,
    parameter length = (2**address_width),
    parameter bus_width = 32,
    parameter instruction_memory = 0
) (
    input clk,
    input rst,
    output rdata_valid,
    input raddr_ready,
    output wdata_ready,
    output waddr_ready,
    output [bus_width-1:0] rdata,
    input rdata_ready,
    output raddr_valid,
    input wdata_valid,
    input waddr_valid,
    input [bus_width-1:0] raddr,
    input [bus_width-1:0] wdata,
    input [bus_width-1:0] waddr
);
reg [7:0] memory [length - 1:0];
`STRING fw_file;
initial begin
    $display("%t: %m memory length: %0d", $time, length);
    if (instruction_memory == `TRUE) begin
        if ($value$plusargs("FW_FILE=%s", fw_file)) begin
            $readmemh(fw_file, memory, 0, length - 1);
        end else begin
            $display("%t: Error: No firmware given. Example: vvp sim.vvp +FW_FILE=fw.hex", $time);
            $finish;
        end
    end
end
endmodule
