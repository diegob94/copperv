`timescale 1ns/1ps
`include "copperv_h.v"

module register_file #(
    parameter reg_length = 2**`REG_WIDTH
) (
    input clk,
    input rst,
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
integer i;
always @(posedge clk) begin
    if(!rst) begin
        for(i = 0; i < reg_length; i = i + 1)
            memory[i] <= 0;
    end if(rd_en && rd != 0) begin
        memory[rd] <= rd_din;
    end else if(rs1_en && rs2_en) begin
        rs1_dout <= memory[rs1];
        rs2_dout <= memory[rs2];
    end else if(rs1_en) begin
        rs1_dout <= memory[rs1];
    end 
end
endmodule
