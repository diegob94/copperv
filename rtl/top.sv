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
parameter clk_per_bit = 217; //115200 @25MHz

wishbone_bus_if #(.dat_width(bus_width),.adr_width(bus_width)) cpu_bus;
wishbone_bus_if #(.dat_width(bus_width),.adr_width(bus_width)) uart_bus;

wb_copperv #(
    .addr_width(bus_width),
    .data_width(bus_width)
) cpu (
    .clock(clock),
    .reset(reset),
    .wb(cpu_bus)
);

wb2uart #(
    .addr_width(bus_width),
    .data_width(bus_width),
    .clk_per_bit(clk_per_bit)
) uart (
    .clock(clock),
    .reset(reset),
    .wb(uart_bus),
    .uart_tx(uart_tx),
    .uart_rx(uart_rx)
);

wb_xbar #(
    .m_count(1),
    .s_count(1),
    .adr_map(0)
) xbar (
    .*,
    .m_arr(`{cpu_bus}),
    .s_arr(`{uart_bus})
);

endmodule
