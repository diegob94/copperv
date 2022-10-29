`timescale 1ns/1ps
`include "copperv_h.v"

module wb_copperv #(
    parameter addr_width = 4,
    parameter data_width = 8,
    parameter strobe_width = addr_width/8,
    parameter resp_width = 1
) (
    input                     clock,
    input                     reset,
    output [addr_width-1:0]   wb_adr,
    output [data_width-1:0]   wb_datwr,
    input  [data_width-1:0]   wb_datrd,
    output                    wb_we,
    output                    wb_stb,
    input                     wb_ack,
    output                    wb_cyc,
    output [strobe_width-1:0] wb_sel
);

    wire ir_data_valid;
    wire ir_addr_ready;
    wire [data_width-1:0] ir_data;
    wire dr_data_valid;
    wire dr_addr_ready;
    wire dw_data_addr_ready;
    wire dw_resp_valid;
    wire [data_width-1:0] dr_data;
    wire [resp_width-1:0] dw_resp;
    wire ir_data_ready;
    wire ir_addr_valid;
    wire [addr_width-1:0] ir_addr;
    wire dr_data_ready;
    wire dr_addr_valid;
    wire dw_data_addr_valid;
    wire dw_resp_ready;
    wire [addr_width-1:0] dr_addr;
    wire [data_width-1:0] dw_data;
    wire [addr_width-1:0] dw_addr;
    wire [strobe_width-1:0] dw_strobe;

    reg [addr_width-1:0]   wb_adr;
    reg [data_width-1:0]   wb_datwr;
    reg                    wb_we;
    reg                    wb_stb;
    reg                    wb_cyc;
    reg [strobe_width-1:0] wb_sel;

    wire [addr_width-1:0]   d_wb_adr;
    wire [data_width-1:0]   d_wb_datwr;
    wire [data_width-1:0]   d_wb_datrd;
    wire                    d_wb_we;
    wire                    d_wb_stb;
    wire                    d_wb_ack;
    wire                    d_wb_cyc;
    wire [strobe_width-1:0] d_wb_sel;

    wire [addr_width-1:0]   i_wb_adr;
    wire [data_width-1:0]   i_wb_datwr;
    wire [data_width-1:0]   i_wb_datrd;
    wire                    i_wb_we;
    wire                    i_wb_stb;
    wire                    i_wb_ack;
    wire                    i_wb_cyc;
    wire [strobe_width-1:0] i_wb_sel;

    reg d_transaction;
    reg i_transaction;

    assign d_wb_datrd = wb_datrd;
    assign i_wb_datrd = wb_datrd;
    assign d_wb_ack = d_transaction ? wb_ack : 0;
    assign i_wb_ack = i_transaction ? wb_ack : 0;

    always @(*) begin
        wb_stb = 0;
        wb_cyc = 0;
        wb_we = 0;
        wb_adr = 0;
        wb_datwr = 0;
        wb_sel = 0;
        d_transaction = d_wb_stb && !i_wb_stb;
        i_transaction = !d_wb_stb && i_wb_stb;
        if(d_transaction) begin
            wb_stb = d_wb_stb;
            wb_cyc = d_wb_cyc;
            wb_we = d_wb_we;
            wb_adr = d_wb_adr;
            wb_datwr = d_wb_datwr;
            wb_sel = d_wb_sel;
        end else if(i_transaction) begin
            wb_stb = i_wb_stb;
            wb_cyc = i_wb_cyc;
            wb_we = i_wb_we;
            wb_adr = i_wb_adr;
            wb_datwr = i_wb_datwr;
            wb_sel = i_wb_sel;
        end
    end

    copperv core(
        .clk(clock),
        .rst(!reset),
        .ir_data_valid(ir_data_valid),
        .ir_addr_ready(ir_addr_ready),
        .ir_data(ir_data),
        .dr_data_valid(dr_data_valid),
        .dr_addr_ready(dr_addr_ready),
        .dw_data_addr_ready(dw_data_addr_ready),
        .dw_resp_valid(dw_resp_valid),
        .dr_data(dr_data),
        .dw_resp(dw_resp),
        .ir_data_ready(ir_data_ready),
        .ir_addr_valid(ir_addr_valid),
        .ir_addr(ir_addr),
        .dr_data_ready(dr_data_ready),
        .dr_addr_valid(dr_addr_valid),
        .dw_data_addr_valid(dw_data_addr_valid),
        .dw_resp_ready(dw_resp_ready),
        .dr_addr(dr_addr),
        .dw_data(dw_data),
        .dw_addr(dw_addr),
        .dw_strobe(dw_strobe)
    );

    wb_adapter #(
        .addr_width(addr_width),
        .data_width(data_width),
        .strobe_width(strobe_width),
        .resp_width(resp_width)
    ) d_adapter (
         .clock(clock),
         .reset(reset),
         .wb_adr(d_wb_adr),
         .wb_datwr(d_wb_datwr),
         .wb_datrd(d_wb_datrd),
         .wb_we(d_wb_we),
         .wb_stb(d_wb_stb),
         .wb_ack(d_wb_ack),
         .wb_cyc(d_wb_cyc),
         .wb_sel(d_wb_sel),
         .bus_r_addr_ready(dr_addr_ready),
         .bus_r_addr_valid(dr_addr_valid),
         .bus_r_addr(dr_addr),
         .bus_r_data_ready(dr_data_ready),
         .bus_r_data_valid(dr_data_valid),
         .bus_r_data(dr_data),
         .bus_w_data_addr_ready(dw_data_addr_ready),
         .bus_w_data_addr_valid(dw_data_addr_valid),
         .bus_w_data(dw_data),
         .bus_w_addr(dw_addr),
         .bus_w_strobe(dw_strobe),
         .bus_w_resp_ready(dw_resp_ready),
         .bus_w_resp_valid(dw_resp_valid),
         .bus_w_resp(dw_resp)
    );

    wb_adapter #(
        .addr_width(addr_width),
        .data_width(data_width),
        .strobe_width(strobe_width),
        .resp_width(resp_width)
    ) i_adapter (
         .clock(clock),
         .reset(reset),
         .wb_adr(i_wb_adr),
         .wb_datwr(i_wb_datwr),
         .wb_datrd(i_wb_datrd),
         .wb_we(i_wb_we),
         .wb_stb(i_wb_stb),
         .wb_ack(i_wb_ack),
         .wb_cyc(i_wb_cyc),
         .wb_sel(i_wb_sel),
         .bus_r_addr_ready(ir_addr_ready),
         .bus_r_addr_valid(ir_addr_valid),
         .bus_r_addr(ir_addr),
         .bus_r_data_ready(ir_data_ready),
         .bus_r_data_valid(ir_data_valid),
         .bus_r_data(ir_data),
         .bus_w_data_addr_ready(),
         .bus_w_data_addr_valid(0),
         .bus_w_data(0),
         .bus_w_addr(0),
         .bus_w_strobe(0),
         .bus_w_resp_ready(0),
         .bus_w_resp_valid(),
         .bus_w_resp()
    );

endmodule
