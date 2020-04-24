`timescale 1ns/1ps
`include "testbench_h.v"
`include "copperv_h.v"

module fake_memory(
    input clk,
    input rst,
    input dr_data_ready,
    input dr_addr_valid,
    input dw_data_addr_valid,
    input dw_resp_ready,
    input [`BUS_WIDTH-1:0] dr_addr,
    input [`BUS_WIDTH-1:0] dw_data,
    input [`BUS_WIDTH-1:0] dw_addr,
    input [(`BUS_WIDTH/8)-1:0] dw_strobe,
    input ir_data_ready,
    input ir_addr_valid,
    input [`BUS_WIDTH-1:0] ir_addr,
    output reg dr_data_valid,
    output dr_addr_ready,
    output dw_data_addr_ready,
    output reg dw_resp_valid,
    output reg [`BUS_WIDTH-1:0] dr_data,
    output reg ir_data_valid,
    output reg ir_addr_ready,
    output reg [`BUS_WIDTH-1:0] ir_data,
    output reg [`BUS_RESP_WIDTH-1:0] dw_resp
);
// fake_memory inputs
wire r_addr_valid;
wire r_data_ready;
wire w_data_addr_valid;
wire w_resp_ready;
wire [`BUS_WIDTH-1:0] r_addr;
wire [`BUS_WIDTH-1:0] w_data;
wire [`BUS_WIDTH-1:0] w_addr;
assign r_addr_valid = ir_addr_valid | dr_addr_valid;
assign r_data_ready = ir_data_ready | dr_data_ready;
assign w_data_addr_valid = dw_data_addr_valid;
assign w_resp_ready = dw_resp_ready;
assign r_addr = ir_addr_valid ? ir_addr : dr_addr;
assign w_data = dw_data;
assign w_addr = dw_addr;
// fake_memory outputs
wire w_resp_valid;
wire [`BUS_RESP_WIDTH-1:0] w_resp;
wire r_addr_ready;
wire r_data_valid;
wire w_data_addr_ready;
wire [`BUS_WIDTH-1:0] r_data;

reg ir_addr_tran;
always @(posedge clk) begin
    if(!rst) begin
        ir_addr_tran <= 0;
    end else begin
        ir_addr_tran <= ir_addr_valid && ir_addr_ready;
    end
end

reg dr_addr_tran;
reg dw_data_addr_tran;
always @(posedge clk) begin
    if(!rst) begin
        dr_addr_tran <= 0;
        dw_data_addr_tran <= 0;
    end else begin
        dr_addr_tran <= dr_addr_valid && dr_addr_ready;
        dw_data_addr_tran <= dw_data_addr_valid && dw_data_addr_ready;
    end
end

always @(*) begin
    if(ir_addr_tran) begin
        ir_data_valid = r_data_valid;
        ir_data = r_data;
    end else begin
        ir_data_valid = 0;
        ir_data = 0;
    end
    if(dr_addr_tran) begin
        dr_data_valid = r_data_valid;
        dr_data = r_data;
    end else begin
        dr_data_valid = 0;
        dr_data = 0;
    end
    if(dw_data_addr_tran) begin
        dw_resp_valid = w_resp_valid;
        dw_resp = w_resp;
    end else begin
        dw_resp_valid = 0;
        dw_resp = 0;
    end
end

assign ir_addr_ready = r_addr_ready;
assign dw_data_addr_ready = w_data_addr_ready;
assign dr_addr_ready = r_addr_ready;

memory u_mem_1 (
    .clk(clk),
    .rst(rst),
    .r_addr_valid(r_addr_valid),
    .r_data_ready(r_data_ready),
    .w_data_addr_valid(w_data_addr_valid),
    .r_addr(r_addr),
    .w_data(w_data),
    .w_addr(w_addr),
    .w_resp_ready(w_resp_ready),
    .w_resp_valid(w_resp_valid),
    .w_resp(w_resp),
    .r_addr_ready(r_addr_ready),
    .r_data_valid(r_data_valid),
    .w_data_addr_ready(w_data_addr_ready),
    .r_data(r_data),
    .w_strobe(dw_strobe)
);
endmodule

module memory #(
    parameter address_width = 16,
    parameter length = (2**address_width)
) (
    input clk,
    input rst,
    input r_addr_valid,
    input r_data_ready,
    input w_data_addr_valid,
    input [`BUS_WIDTH-1:0] r_addr,
    input [`BUS_WIDTH-1:0] w_data,
    input [`BUS_WIDTH-1:0] w_addr,
    input w_resp_ready,
    input [(`BUS_WIDTH/8)-1:0] w_strobe,
    output reg w_resp_valid,
    output reg [`BUS_RESP_WIDTH-1:0] w_resp,
    output reg r_addr_ready,
    output r_data_valid,
    output reg w_data_addr_ready,
    output [`BUS_WIDTH-1:0] r_data
);
reg [7:0] memory [length - 1:0];
`STRING hex_file;
initial begin
    $display("%t: %m length: %0d", $time, length);
    if ($value$plusargs("HEX_FILE=%s", hex_file)) begin
        $readmemh(hex_file, memory, 0, length - 1);
    end else begin
        $display($time, "Error: %m no hex file given. Example: vvp sim.vvp +HEX_FILE=test.hex");
        $finish;
    end
end
always @(posedge clk)
    if(!rst) begin
        r_addr_ready <= 1;
        w_data_addr_ready <= 1;
    end
reg r_data_valid;
reg [`BUS_WIDTH-1:0] r_data;
reg read_addr_tran;
reg read_data_tran;
reg write_data_addr_tran;
reg write_resp_tran;
always @(*) begin
    read_addr_tran = r_addr_valid && r_addr_ready;
    read_data_tran = r_data_valid && r_data_ready;
    write_data_addr_tran = w_data_addr_valid && w_data_addr_ready;
    write_resp_tran = w_resp_valid && w_resp_ready;
end
always @(posedge clk) begin
    if(!rst) begin
        r_data <= 0;
        r_data_valid <= 0;
    end else if(read_addr_tran) begin
        r_data <= {
                memory[r_addr+3],
                memory[r_addr+2],
                memory[r_addr+1],
                memory[r_addr+0]
        };
        r_data_valid <= 1;
    end else if(read_data_tran) begin
        r_data_valid <= 0;
    end
end
always @(posedge clk) begin
    if(!rst) begin
        w_resp <= 0;
        w_resp_valid <= 0;
    end else if(write_data_addr_tran) begin
        if(w_strobe[3]) memory[w_addr+3] <= w_data[31:24];
        if(w_strobe[2]) memory[w_addr+2] <= w_data[23:16];
        if(w_strobe[1]) memory[w_addr+1] <= w_data[15:8];
        if(w_strobe[0]) memory[w_addr+0] <= w_data[7:0];
        w_resp <= `DATA_WRITE_RESP_OK;
        w_resp_valid <= 1;
    end else if(write_resp_tran) begin
        w_resp_valid <= 0;
    end
end
//always @(negedge clk)
//    if (read_addr_tran)
//        $display($time, {msg_prefix, "read addr 0x%0X data 0x%0X"}, r_addr, r_data);
endmodule
