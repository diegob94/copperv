`timescale 1ns/1ps

module #(
    parameter addr_width = 4,
    parameter data_width = 8
) wb_adapter(
    input                   clock,
    output [addr_width-1:0] wb_adr,
    output [data_width-1:0] wb_datwr,
    input  [data_width-1:0] wb_datrd,
    output                  wb_we,
    output                  wb_stb,
    input                   wb_ack,
    output                  wb_cyc
    output  dr_addr_ready,
    input   dr_addr_valid,
    input   dr_data_ready,
    output  dr_data_valid,
    output  [`BUS_WIDTH-1:0] dr_data,
    input   [`BUS_WIDTH-1:0] dr_addr,
    input   dw_data_addr_ready,
    output  dw_data_addr_valid,
    output  dw_resp_ready,
    input   dw_resp_valid,
    input [`BUS_RESP_WIDTH-1:0] dw_resp,
    output [`BUS_WIDTH-1:0] dw_data,
    output [`BUS_WIDTH-1:0] dw_addr,
    output [(`BUS_WIDTH/8)-1:0] dw_strobe
)

endmodule
