`timescale 1ns/1ps

`define UNSIGNED(x,wlhs,high,low) {{(wlhs-(high-low+1)){1'b0}},x[high:low]}

module arith_logic_unit import copperv_pkg::*;
  ( 
    input data_td alu_din1,
    input data_td alu_din2,
    input alu_op_e alu_op,
    output data_td alu_dout,
    output alu_comp_s alu_comp
  );
  always @(*) begin
    alu_dout = 0;
    case (alu_op)
      alu_op_nop:  alu_dout = {data_width{1'bx}};
      alu_op_add:  alu_dout = alu_din1 + alu_din2; 
      alu_op_sub:  alu_dout = alu_din1 - alu_din2;
      alu_op_and:  alu_dout = alu_din1 & alu_din2;
      alu_op_sll:  alu_dout = alu_din1 << alu_din2;
      alu_op_srl:  alu_dout = alu_din1 >> alu_din2;
      alu_op_sra:  alu_dout = $signed(alu_din1) >>> alu_din2;
      alu_op_xor:  alu_dout = alu_din1 ^ alu_din2;
      alu_op_or:   alu_dout = alu_din1 | alu_din2;
      alu_op_slt:  alu_dout = data_td'(alu_comp.lt);
      alu_op_sltu: alu_dout = data_td'(alu_comp.ltu);
    endcase
  end
  always @(*) begin
    alu_comp.eq  = alu_din1 == alu_din2;
    alu_comp.lt  = $signed(alu_din1) < $signed(alu_din2);
    alu_comp.ltu = alu_din1 < alu_din2;
  end
endmodule

