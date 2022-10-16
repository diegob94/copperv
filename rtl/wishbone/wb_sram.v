`timescale 1ns/1ps
`default_nettype none

module wb_sram #(
    parameter addr_width = 32,
    parameter data_width = 32,
    parameter strobe_width = addr_width/8,
    parameter length = 128
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
    input  [strobe_width-1:0] wb_sel,
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

    sram_32_sp sram(
        .clock(clock),
        .wen(wb_we),
        .en(en_sram),
        .wmask(wb_sel),
        .addr(wb_adr),
        .din(wb_datwr),
        .dout(wb_datrd)
    );

endmodule

module sram_32_sp #(
    parameter data_width = 32, // fixed
    parameter addr_width = 8, // dynamic
    parameter mask_width = data_width/8 // fixed
) (
    input                    clock,
    input                    wen,
    input                    en,
    input  [mask_width-1:0]  wmask,
    input  [addr_width-1:0]  addr,
    input  [data_width-1:0]  din,
    output [data_width-1:0]  dout,
);
    parameter length = 1 << addr_width;

    `ifdef FORMAL
        `include "formal/sram_32_sp.v"
    `endif

    reg [data_width-1:0] mem [length-1:0];
    reg [data_width-1:0] dout;

    always @(posedge clock)
        if(en && wen) begin
            if(wmask[0])
                mem[addr][7:0] <= din[7:0];
            if(wmask[1])
                mem[addr][15:8] <= din[15:8];
            if(wmask[2])
                mem[addr][23:16] <= din[23:16];
            if(wmask[3])
                mem[addr][31:24] <= din[31:24];
        end

    always @(posedge clock)
        if(en && !wen)
            dout <= mem[addr];

endmodule

