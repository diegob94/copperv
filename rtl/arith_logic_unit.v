`timescale 1ns/1ps
`include "copperv_h.v"

module arith_logic_unit (
    input [`DATA_WIDTH-1:0] alu_din1,
    input [`DATA_WIDTH-1:0] alu_din2,
    input [`FUNCT_WIDTH-1:0] funct,
    output [`DATA_WIDTH-1:0] alu_dout
);
reg [`DATA_WIDTH-1:0] alu_dout;
always @(*) begin
    case (funct)
        `FUNCT_ADD: alu_dout = alu_din1 + alu_din2;
        `FUNCT_SUB: alu_dout = alu_din1 - alu_din2;
    endcase
end
endmodule
