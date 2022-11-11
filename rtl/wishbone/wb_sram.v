`timescale 1ns/1ps
`default_nettype none

module wb_sram #(
    parameter addr_width = 32,
    parameter data_width = 32,
    parameter strobe_width = addr_width/8,
    parameter sram_addr_width = 8
)(
    input                     clock,
    input                     reset,
    input  [addr_width-1:0]   wb_adr,
    input  [data_width-1:0]   wb_datwr,
    output [data_width-1:0]   wb_datrd,
    input                     wb_we,
    input                     wb_stb,
    output                    wb_ack,
    input                     wb_cyc,
    input  [strobe_width-1:0] wb_sel
);

    `ifdef FORMAL
        `include "formal/wb_sram.v"
    `endif

    wire [data_width-1:0] wb_datrd;
    reg wb_ack;
    wire en_sram;

    assign en_sram = (wb_stb && wb_cyc) && !wb_ack;

    always @(posedge clock)
        if(reset)
            wb_ack <= 0;
        else if(!wb_ack && wb_stb && wb_cyc)
            wb_ack <= 1;
        else
            wb_ack <= 0;

    sram_1r1w #(.addr_width(sram_addr_width)) sram(
        .clock(clock),
        .wen(wb_we),
        .en(en_sram),
        .wmask(wb_sel),
        .addr(wb_adr),
        .din(wb_datwr),
        .dout(wb_datrd)
    );

endmodule

