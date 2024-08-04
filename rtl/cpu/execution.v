`timescale 1ns/1ps

`define UNSIGNED(x,wlhs,high,low) {{(wlhs-(high-low+1)){1'b0}},x[high:low]}

module arith_logic_unit (
    input [data_width-1:0] alu_din1,
    input [data_width-1:0] alu_din2,
    input [alu_op_width-1:0] alu_op,
    output reg [data_width-1:0] alu_dout,
    output reg [alu_comp_width-1:0] alu_comp
);
always @(*) begin
    alu_dout = 0;
    case (alu_op)
        alu_op_nop:  alu_dout = {data_width{1'bx}};
        alu_op_add:  alu_dout = alu_din1 + alu_din2; 
        alu_op_sub:  alu_dout = alu_din1 - alu_din2;
        alu_op_and:  alu_dout = alu_din1 & alu_din2;
        alu_op_sll:  alu_dout = alu_din1 << alu_din2[alu_shift_din2_width-1:0];
        alu_op_srl:  alu_dout = alu_din1 >> alu_din2[alu_shift_din2_width-1:0];
        alu_op_sra:  alu_dout = $signed(alu_din1) >>> alu_din2[alu_shift_din2_width-1:0];
        alu_op_xor:  alu_dout = alu_din1 ^ alu_din2;
        alu_op_or:   alu_dout = alu_din1 | alu_din2;
        alu_op_slt:  alu_dout = `UNSIGNED(alu_comp,32,alu_comp_lt,alu_comp_lt);
        alu_op_sltu: alu_dout = `UNSIGNED(alu_comp,32,alu_comp_ltu,alu_comp_ltu);
    endcase
end
always @(*) begin
    alu_comp[alu_comp_eq]  = alu_din1 == alu_din2;
    alu_comp[alu_comp_lt]  = $signed(alu_din1) < $signed(alu_din2);
    alu_comp[alu_comp_ltu] = alu_din1 < alu_din2;
end
endmodule

