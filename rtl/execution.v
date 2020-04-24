`timescale 1ns/1ps
`include "copperv_h.v"

module arith_logic_unit (
    input [`DATA_WIDTH-1:0] alu_din1,
    input [`DATA_WIDTH-1:0] alu_din2,
    input [`ALU_OP_WIDTH-1:0] alu_op,
    output reg [`DATA_WIDTH-1:0] alu_dout,
    output reg [`ALU_COMP_WIDTH-1:0] alu_comp
);
always @(*) begin
    alu_dout = 0;
    case (alu_op)
        `ALU_OP_NOP:  alu_dout = {`DATA_WIDTH{1'bx}};
        `ALU_OP_ADD:  alu_dout = alu_din1 + alu_din2;
        `ALU_OP_SUB:  alu_dout = alu_din1 - alu_din2;
        `ALU_OP_AND:  alu_dout = alu_din1 & alu_din2;
        `ALU_OP_SLL:  alu_dout = alu_din1 << alu_din2[`ALU_SHIFT_DIN2_WIDTH-1:0];
        `ALU_OP_SRL:  alu_dout = alu_din1 >> alu_din2[`ALU_SHIFT_DIN2_WIDTH-1:0];
        `ALU_OP_SRA:  alu_dout = $signed(alu_din1) >>> alu_din2[`ALU_SHIFT_DIN2_WIDTH-1:0];
        `ALU_OP_XOR:  alu_dout = alu_din1 ^ alu_din2;
        `ALU_OP_OR:   alu_dout = alu_din1 | alu_din2;
        `ALU_OP_SLT:  alu_dout = `UNSIGNED(alu_comp,32,`ALU_COMP_LT,`ALU_COMP_LT);
        `ALU_OP_SLTU: alu_dout = `UNSIGNED(alu_comp,32,`ALU_COMP_LTU,`ALU_COMP_LTU);
    endcase
end
always @(*) begin
    alu_comp[`ALU_COMP_EQ]  = alu_din1 == alu_din2;
    alu_comp[`ALU_COMP_LT]  = $signed(alu_din1) < $signed(alu_din2);
    alu_comp[`ALU_COMP_LTU] = alu_din1 < alu_din2;
end
endmodule

