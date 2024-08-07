`timescale 1ns/1ps

module register_file import copperv_pkg::*;
  (
    input clk,
    input rst,
    input rd_en,
    input rs1_en,
    input rs2_en,
    input reg_adr_td rd,
    input reg_adr_td rs1,
    input reg_adr_td rs2,
    input data_td rd_din,
    output data_td rs1_dout,
    output data_td rs2_dout
  );
  parameter reg_length = 2**$bits(reg_adr_td);
  data_td mem [reg_length-1:0];
  integer i;
  always @(posedge clk) begin
      if(rst) begin
          for(i = 0; i < reg_length; i = i + 1)
              mem[i] <= 0;
      end if(rd_en && rd != 0) begin
          mem[rd] <= rd_din;
      end else if(rs1_en && rs2_en) begin
          rs1_dout <= mem[rs1];
          rs2_dout <= mem[rs2];
      end else if(rs1_en) begin
          rs1_dout <= mem[rs1];
      end 
  end
endmodule
