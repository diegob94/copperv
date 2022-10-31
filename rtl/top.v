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
parameter sel_width = bus_width/8;
parameter clk_per_bit = 217; //115200 @25MHz

wire [bus_width-1:0] wb_cpu_adr;
wire [bus_width-1:0] wb_cpu_datwr;
wire [bus_width-1:0] wb_cpu_datrd;
wire                 wb_cpu_we;
wire                 wb_cpu_stb;
wire                 wb_cpu_ack;
wire                 wb_cpu_cyc;
wire [sel_width-1:0] wb_cpu_sel;

wire [bus_width-1:0] wb_wb2uart_adr;
wire [bus_width-1:0] wb_wb2uart_datwr;
wire [bus_width-1:0] wb_wb2uart_datrd;
wire                 wb_wb2uart_we;
wire                 wb_wb2uart_stb;
wire                 wb_wb2uart_ack;
wire                 wb_wb2uart_cyc;
wire [sel_width-1:0] wb_wb2uart_sel;

wb_copperv #(
    .addr_width(bus_width),
    .data_width(bus_width)
) cpu (
    .clock(clock),
    .reset(reset),
    .wb_adr(wb_cpu_adr),
    .wb_datwr(wb_cpu_datwr),
    .wb_datrd(wb_cpu_datrd),
    .wb_we(wb_cpu_we),
    .wb_stb(wb_cpu_stb),
    .wb_ack(wb_cpu_ack),
    .wb_cyc(wb_cpu_cyc),
    .wb_sel(wb_cpu_sel)
);

wb2uart #(
    .addr_width(bus_width),
    .data_width(bus_width),
    .clk_per_bit(clk_per_bit)
) uart (
    .clock(clock),
    .reset(reset),
    .wb_adr(wb_wb2uart_adr),
    .wb_datwr(wb_wb2uart_datwr),
    .wb_datrd(wb_wb2uart_datrd),
    .wb_we(wb_wb2uart_we),
    .wb_stb(wb_wb2uart_stb),
    .wb_ack(wb_wb2uart_ack),
    .wb_cyc(wb_wb2uart_cyc),
    .wb_sel(wb_wb2uart_sel),
    .uart_tx(uart_tx),
    .uart_rx(uart_rx)
);

wbxbar #(
    .NM(1),
    .NS(1),
    .AW(bus_width),
    .DW(bus_width),
    .SLAVE_ADDR({{32'd0}}),
    .SLAVE_MASK(0)
) xbar (
    .i_clk(clock),
    .i_reset(reset),
    .i_mcyc({wb_cpu_cyc}),
    .i_mstb({wb_cpu_stb}),
    .i_mwe({wb_cpu_we}),
    .i_maddr({wb_cpu_adr}),
    .i_mdata({wb_cpu_datwr}),
    .i_msel({wb_cpu_sel}),
    .o_mack({wb_cpu_ack}),
    .o_mdata({wb_cpu_datrd}),
    .o_scyc({wb_wb2uart_cyc}),
    .o_sstb({wb_wb2uart_stb}),
    .o_swe({wb_wb2uart_we}),
    .o_saddr({wb_wb2uart_adr}),
    .o_sdata({wb_wb2uart_datwr}),
    .o_ssel({wb_wb2uart_sel}),
    .i_sstall({sel_width{1'b0}}),
    .i_sack({wb_wb2uart_ack}),
    .i_sdata({wb_wb2uart_datrd}),
    .i_serr({1'b0})
);

endmodule
