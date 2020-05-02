`timescale 1ns/1ps
`include "copperv_h.v"

module native_memory #(
    parameter address_width = 8,
    parameter length = (2**address_width),
    parameter instruction_memory = 0
) (
    input clk,
    input rst,
    input raddr_valid,
    input rdata_ready,
    input wdata_valid,
    input waddr_valid,
    input [`BUS_WIDTH-1:0] raddr,
    input [`BUS_WIDTH-1:0] wdata,
    input [`BUS_WIDTH-1:0] waddr,
    output raddr_ready,
    output rdata_valid,
    output wdata_ready,
    output waddr_ready,
    output [`BUS_WIDTH-1:0] rdata
);
reg [7:0] memory [length - 1:0];
`STRING fw_file;
initial begin
    $display("%t: %m length: %0d", $time, length);
    if (instruction_memory == `TRUE) begin
        if ($value$plusargs("FW_FILE=%s", fw_file)) begin
            $readmemh(fw_file, memory, 0, length - 1);
        end else begin
            $display("%t: Error: No firmware given. Example: vvp sim.vvp +FW_FILE=fw.hex", $time);
            $finish;
        end
    end
end
assign raddr_ready = 1;
reg rdata_valid;
reg [`BUS_WIDTH-1:0] rdata;
reg read_addr_tran;
reg read_data_tran;
always @(*) begin
    read_addr_tran = raddr_valid && raddr_ready;
    read_data_tran = rdata_valid && rdata_ready;
end
always @(posedge clk) begin
    if(!rst) begin
        rdata <= 0;
        rdata_valid <= 0;
    end else if(read_addr_tran) begin
        rdata <= {
                memory[raddr+3],
                memory[raddr+2],
                memory[raddr+1],
                memory[raddr+0]
        };
        rdata_valid <= 1;
    end else if(read_data_tran) begin
        rdata_valid <= 0;
    end
end
endmodule
