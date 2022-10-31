`timescale 1ns/1ps
`default_nettype none

module wb_adapter #(
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
    output [strobe_width-1:0] wb_sel,
    output                    bus_r_addr_ready,
    input                     bus_r_addr_valid,
    input  [addr_width-1:0]   bus_r_addr,
    input                     bus_r_data_ready,
    output                    bus_r_data_valid,
    output [data_width-1:0]   bus_r_data,
    output                    bus_w_data_addr_ready,
    input                     bus_w_data_addr_valid,
    input  [data_width-1:0]   bus_w_data,
    input  [addr_width-1:0]   bus_w_addr,
    input  [strobe_width-1:0] bus_w_strobe,
    input                     bus_w_resp_ready,
    output                    bus_w_resp_valid,
    output [resp_width-1:0]   bus_w_resp
);
    reg [data_width-1:0] wb_datwr;
    reg [addr_width-1:0] wb_adr;
    reg [strobe_width-1:0] wb_sel;
    reg wb_we;
    reg wb_cyc;
    reg wb_stb;
    reg [resp_width-1:0] bus_w_resp;
    reg bus_w_resp_valid;
    reg [data_width-1:0] bus_r_data;
    reg bus_r_data_valid;
    assign bus_w_data_addr_ready = 1;
    assign bus_r_addr_ready = 1;
    always @(posedge clock) begin
        if(reset) begin
            wb_cyc <= 0;
        end else if(bus_r_addr_ready && bus_r_addr_valid) begin
            wb_we <= 0;
            wb_cyc <= 1;
        end else if(bus_w_data_addr_ready && bus_w_data_addr_valid) begin
            wb_we <= 1;
            wb_cyc <= 1;
        end else if(wb_ack) begin
            wb_cyc <= 0;
        end
    end
    always @(posedge clock) begin
        if(reset) begin
            wb_stb <= 0;
        end else if(bus_r_addr_ready && bus_r_addr_valid) begin
            wb_stb <= 1;
        end else if(bus_w_data_addr_ready && bus_w_data_addr_valid) begin
            wb_stb <= 1;
        end else if(wb_stb) begin
            wb_stb <= 0;
        end
    end
    always @(posedge clock) begin
        if(reset) begin
            bus_w_resp_valid <= 0;
        end else if(wb_ack && wb_we) begin
            bus_w_resp <= 1;
            bus_w_resp_valid <= 1;
        end else if(bus_w_resp_ready && bus_w_resp_valid) begin
            bus_w_resp_valid <= 0;
        end
    end
    always @(posedge clock) begin
        if(reset) begin
            bus_r_data_valid <= 0;
        end else if(wb_ack && !wb_we) begin
            bus_r_data <= wb_datrd;
            bus_r_data_valid <= 1;
        end else if(bus_r_data_ready && bus_r_data_valid) begin
            bus_r_data_valid <= 0;
        end
    end
    always @(posedge clock) begin
        if(bus_r_addr_ready && bus_r_addr_valid) begin
            wb_adr <= bus_r_addr;
        end else if(bus_w_data_addr_ready && bus_w_data_addr_valid) begin
            wb_adr <= bus_w_addr;
            wb_datwr <= bus_w_data;
            wb_sel <= bus_w_strobe;
        end
    end
endmodule
