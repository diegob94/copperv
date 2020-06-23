`timescale 1ns/1ps
`include "copperv_h.v"

module arith_logic_unit (
    input [`DATA_WIDTH-1:0] alu_din1,
    input [`DATA_WIDTH-1:0] alu_din2,
    input [`ALU_OP_WIDTH-1:0] alu_op,
    output [`DATA_WIDTH-1:0] alu_dout,
    output alu_comp
);
reg [`DATA_WIDTH-1:0] alu_dout;
reg alu_comp;
reg sign;
wire eq;
wire lt;
wire gt;
always @(*) begin
    sign = 0;
    alu_dout = 0;
    case (alu_op)
        `ALU_OP_NOP: alu_dout = {`DATA_WIDTH{1'bx}};
        `ALU_OP_ADD: alu_dout = alu_din1 + alu_din2;
        `ALU_OP_SUB: alu_dout = alu_din1 - alu_din2;
    endcase
end
always @(*)
    alu_comp = eq;
comparator comp(
    .a(alu_din1),
    .b(alu_din2),
    .sign(sign),
    .eq(eq),
    .gt(gt),
    .lt(lt)
);
endmodule

module comparator(
    input [`DATA_WIDTH-1:0] a,
    input [`DATA_WIDTH-1:0] b,
    input sign,
    output eq,
    output gt,
    output lt
);
reg eq;
reg gt;
reg lt;
reg signed [`DATA_WIDTH-1:0] a_s;
reg signed [`DATA_WIDTH-1:0] b_s;
always @(*) begin
    a_s = a;
    b_s = b;
    if(!sign) begin
        eq = a == b;
        lt = a > b;
        gt = a < b;
    end else begin
        eq = a_s == b_s;
        lt = a_s > b_s;
        gt = a_s < b_s;
    end
end
endmodule
