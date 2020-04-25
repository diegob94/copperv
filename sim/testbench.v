module tb();
parameter bus_width = 32;
reg clk;
reg rst;
reg d_rdata_valid;
reg d_raddr_ready;
reg d_wdata_ready;
reg d_waddr_ready;
reg [bus_width-1:0] d_rdata;
reg i_rdata_valid;
reg i_raddr_ready;
reg i_wdata_ready;
reg i_waddr_ready;
reg [bus_width-1:0] i_rdata;
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
endmodule
