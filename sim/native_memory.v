`timescale 1ns/1ps
`include "testbench_h.v"
`include "copperv_h.v"

module native_memory #(
    parameter address_width = 8,
    parameter length = (2**address_width),
    parameter instruction_memory = 0
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
    output reg w_resp_valid,
    output reg [`BUS_RESP_WIDTH-1:0] w_resp,
    output reg r_addr_ready,
    output r_data_valid,
    output reg w_data_addr_ready,
    output [`BUS_WIDTH-1:0] r_data
);
parameter msg_prefix = instruction_memory ? ": I_MEMORY: ":": D_MEMORY: ";
reg [7:0] memory [length - 1:0];
`STRING hex_file;
initial begin
    $display("%t: %m length: %0d", $time, length);
    if (instruction_memory == `TRUE) begin
        if ($value$plusargs("HEX_FILE=%s", hex_file)) begin
            $readmemh(hex_file, memory, 0, length - 1);
        end else begin
            $display($time, {msg_prefix, "Error: No hex file given. Example: vvp sim.vvp +HEX_FILE=test.hex"});
            $finish;
        end
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
        memory[w_addr+3] <= w_data[31:24];
        memory[w_addr+2] <= w_data[23:16];
        memory[w_addr+1] <= w_data[15:8];
        memory[w_addr+0] <= w_data[7:0];
        w_resp <= `DATA_WRITE_RESP_OK;
        w_resp_valid <= 1;
    end else if(write_resp_tran) begin
        w_resp_valid <= 0;
    end
end
always @(negedge clk)
    if (read_addr_tran)
        $display($time, {msg_prefix, "read addr 0x%0X data 0x%0X"}, r_addr, r_data);
endmodule
