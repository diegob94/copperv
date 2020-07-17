`timescale 1ns/1ps
`include "copperv_h.v"

module arith_logic_unit (
    input [`DATA_WIDTH-1:0] alu_din1,
    input [`DATA_WIDTH-1:0] alu_din2,
    input [`ALU_OP_WIDTH-1:0] alu_op,
    output reg [`DATA_WIDTH-1:0] alu_dout,
    output reg [`ALU_COMP_WIDTH-1:0] alu_comp
);
reg sign;
wire eq;
wire lt;
wire ltu;
always @(*) begin
    sign = 0;
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
        `ALU_OP_SLT:  alu_dout = lt;
        `ALU_OP_SLTU: alu_dout = ltu;
    endcase
end
always @(*) begin
    alu_comp[`ALU_COMP_EQ]  = eq;
    alu_comp[`ALU_COMP_LT]  = lt;
    alu_comp[`ALU_COMP_LTU] = ltu;
end
comparator comp(
    .a(alu_din1),
    .b(alu_din2),
    .eq(eq),
    .lt(lt),
    .ltu(ltu)
);
endmodule

module comparator(
    input [`DATA_WIDTH-1:0] a,
    input [`DATA_WIDTH-1:0] b,
    output reg eq,
    output reg gt,
    output reg lt,
    output reg equ,
    output reg gtu,
    output reg ltu
);
reg signed [`DATA_WIDTH-1:0] a_s;
reg signed [`DATA_WIDTH-1:0] b_s;
always @(*) begin
    a_s = a;
    b_s = b;
    equ = a == b;
    ltu = a < b;
    gtu = a > b;
    eq = a_s == b_s;
    lt = a_s < b_s;
    gt = a_s > b_s;
end
endmodule
