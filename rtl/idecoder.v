`timescale 1ns/1ps
`include "copperv_h.v"

module idecoder (
    input [`INST_WIDTH-1:0] inst,
    output [`OPCODE_WIDTH-1:0] opcode,
    output [`IMM_WIDTH-1:0] imm,
    output [`INST_TYPE_WIDTH-1:0] inst_type,
    output [`REG_WIDTH-1:0] rd,
    output [`REG_WIDTH-1:0] rs1,
    output [`REG_WIDTH-1:0] rs2,
    output [`FUNCT_WIDTH-1:0] funct
);
reg [`INST_TYPE_WIDTH-1:0] inst_type;
reg [`IMM_WIDTH-1:0] imm;
reg [`OPCODE_WIDTH-1:0] opcode;
reg [`FUNCT_WIDTH-1:0] funct;
reg [`REG_WIDTH-1:0] rd;
reg [`REG_WIDTH-1:0] rs1;
reg [`REG_WIDTH-1:0] rs2;
always @(*) begin
    opcode = inst[6:0];
    imm = 0;
    inst_type = 0;
    funct = 0;
    rd = 0;
    rs1 = 0;
    rs2 = 0;
    case (opcode)
        {6'h0D, 2'b11}: begin // LUI
            inst_type = `INST_TYPE_IMM;
            imm = {inst[31:12], 12'b0};
            rd = inst[11:7];
        end
        {6'h04, 2'b11}: begin // Reg-Inmmediate
            inst_type = `INST_TYPE_INT_IMM;
            imm = {{21{inst[31]}}, inst[30:20]};
            rd = inst[11:7];
            rs1 = inst[19:15];
            funct = {1'b0, inst[14:12]};
        end
        {6'h0C, 2'b11}: begin // Reg-reg
            inst_type = `INST_TYPE_INT_REG;
            rs2 = inst[24:20];
            funct = {inst[31:25] == 7'd32 ? 1'b1 : 1'b0, inst[14:12]};
        end
        {6'h18, 2'b11}: begin
            inst_type = `INST_TYPE_BRANCH;
            imm = {{19{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
        end
    endcase
end
endmodule
