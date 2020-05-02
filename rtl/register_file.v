`timescale 1ns/1ps
`include "copperv_h.v"

module register_file #(
    parameter reg_length = 2**`REG_WIDTH
) (
    input clk,
    input rd_en,
    input rs1_en,
    input rs2_en,
    input [`REG_WIDTH-1:0] rd,
    input [`REG_WIDTH-1:0] rs1,
    input [`REG_WIDTH-1:0] rs2,
    input [`DATA_WIDTH-1:0] rd_din,
    output [`DATA_WIDTH-1:0] rs1_dout,
    output [`DATA_WIDTH-1:0] rs2_dout
);
reg [`DATA_WIDTH-1:0] rs1_dout;
reg [`DATA_WIDTH-1:0] rs2_dout;
reg [`DATA_WIDTH-1:0] memory [reg_length-1:0];
always @(posedge clk) begin
    if(rd_en) begin
        memory[rd] <= rd_din;
    end else if(rs1_en && rs2_en) begin
        rs1_dout <= rs1 == 0 ? 0 : memory[rs1];
        rs2_dout <= rs2 == 0 ? 0 : memory[rs2];
    end else if(rs1_en) begin
        rs1_dout <= rs1 == 0 ? 0 : memory[rs1];
    end 
end
endmodule
