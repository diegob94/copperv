module copperv #(
    parameter bus_width = 32
) (
    input clk,
    input rst,
    input d_rdata_valid,
    input d_raddr_ready,
    input d_wdata_ready,
    input d_waddr_ready,
    input [bus_width-1:0] d_rdata,
    input i_rdata_valid,
    input i_raddr_ready,
    input i_wdata_ready,
    input i_waddr_ready,
    input [bus_width-1:0] i_rdata,
    output d_rdata_ready,
    output d_raddr_valid,
    output d_wdata_valid,
    output d_waddr_valid,
    output [bus_width-1:0] d_raddr,
    output [bus_width-1:0] d_wdata,
    output [bus_width-1:0] d_waddr,
    output i_rdata_ready,
    output i_raddr_valid,
    output i_wdata_valid,
    output i_waddr_valid,
    output [bus_width-1:0] i_raddr,
    output [bus_width-1:0] i_wdata,
    output [bus_width-1:0] i_waddr
);

endmodule
