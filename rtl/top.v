`timescale 1ns/1ps
`default_nettype none
`include "copperv_h.v"

module top (
    input clock,
    input reset,
    input uart_rx,
    output uart_tx
);
parameter bus_width = `BUS_WIDTH;
parameter strobe_width = bus_width/8;

wire [bus_width-1:0]    wb_adr;
wire [bus_width-1:0]    wb_datwr;
wire [bus_width-1:0]    wb_datrd;
wire                    wb_we;
wire                    wb_stb;
wire                    wb_ack;
wire                    wb_cyc;
wire [strobe_width-1:0] wb_sel;

copperv_wb #(
    .addr_width(bus_width),
    .data_width(bus_width)
) cpu (
    .clock(clock),
    .reset(reset),
    .wb_adr(wb_adr),
    .wb_datwr(wb_datwr),
    .wb_datrd(wb_datrd),
    .wb_we(wb_we),
    .wb_stb(wb_stb),
    .wb_ack(wb_ack),
    .wb_cyc(wb_cyc),
    .wb_sel(wb_sel)
);

wb2uart #(
    .addr_width(bus_width),
    .data_width(bus_width),
    .clk_per_bit(217) // 115200 @25MHz
) uart (
    .clock(clock),
    .reset(reset),
    .wb_adr(wb_adr),
    .wb_datwr(wb_datwr),
    .wb_datrd(wb_datrd),
    .wb_we(wb_we),
    .wb_stb(wb_stb),
    .wb_ack(wb_ack),
    .wb_cyc(wb_cyc),
    .wb_sel(wb_sel),
    .uart_tx(uart_tx),
    .uart_rx(uart_rx)
);

endmodule
