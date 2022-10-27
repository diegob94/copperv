`timescale 1ns/1ps
`default_nettype none
`include "copperv_h.v"
//`include "wishbone.sv"

module top (
    input clock,
    input reset,
    input uart_rx,
    output uart_tx
);
parameter bus_width = `BUS_WIDTH;
parameter strobe_width = bus_width/8;
parameter clk_per_bit = 217; //115200 @25MHz

wishbone_bus_if #(.dat_width(bus_width),.adr_width(bus_width)) m_arr [1-1:0] ();
wishbone_bus_if #(.dat_width(bus_width),.adr_width(bus_width)) s_arr [1-1:0] ();

wb_copperv #(
    .addr_width(bus_width),
    .data_width(bus_width)
) cpu (
    .clock(clock),
    .reset(reset),
    .wb(m_arr[0])
);

wb2uart #(
    .addr_width(bus_width),
    .data_width(bus_width),
    .clk_per_bit(clk_per_bit)
) uart (
    .clock(clock),
    .reset(reset),
    .wb(s_arr[0]),
    .uart_tx(uart_tx),
    .uart_rx(uart_rx)
);

wb_xbar #(
    .m_count(1),
    .s_count(1),
    .adr_map(0)
) xbar (.*);

endmodule
