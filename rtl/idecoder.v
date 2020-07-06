`timescale 1ns/1ps
`include "copperv_h.v"

module idecoder (
    input [`INST_WIDTH-1:0] inst,
    output reg [`IMM_WIDTH-1:0] imm,
    output reg [`INST_TYPE_WIDTH-1:0] inst_type,
    output reg [`REG_WIDTH-1:0] rd,
    output reg [`REG_WIDTH-1:0] rs1,
    output reg [`REG_WIDTH-1:0] rs2,
    output reg [`FUNCT_WIDTH-1:0] funct
);
reg [`OPCODE_WIDTH-1:0] opcode;
reg [`FUNCT3_WIDTH-1:0] funct3;
reg [`FUNCT7_WIDTH-1:0] funct7;
always @(*) begin
    inst_type = 0;
    funct = 0;
    imm = 0;
    rs1 = 0;
    rs2 = 0;
    rd = 0;
    funct3 = 0;
    funct7 = 0;
    opcode = inst[6:0];
    case (opcode)
        `OPCODE_LUI: begin
            inst_type = `INST_TYPE_IMM;
            decode_u_type(inst);
        end
        `OPCODE_JAL: begin
            inst_type = `INST_TYPE_JAL;
            decode_j_type(inst);
        end
        `OPCODE_JALR: begin
            inst_type = `INST_TYPE_JALR;
            decode_i_type(inst);
        end
        `OPCODE_AUIPC: begin
            inst_type = `INST_TYPE_AUIPC;
            decode_u_type(inst);
        end
        `OPCODE_INT_IMM: begin
            inst_type = `INST_TYPE_INT_IMM;
            decode_i_type(inst);
            case (funct3)
                3'd0: funct = `FUNCT_ADD;
                3'd7: funct = `FUNCT_AND;
            endcase
        end
        `OPCODE_INT_REG: begin 
            inst_type = `INST_TYPE_INT_REG;
            decode_r_type(inst);
            case ({funct7, funct3})
                {7'd0, 3'd0}: funct = `FUNCT_ADD;
                {7'd32,3'd0}: funct = `FUNCT_SUB;
                {7'd0, 3'd7}: funct = `FUNCT_AND;
            endcase
        end
        `OPCODE_BRANCH: begin
            inst_type = `INST_TYPE_BRANCH;
            decode_b_type(inst);
            case (funct3)
                3'd0: funct = `FUNCT_EQ;
                3'd1: funct = `FUNCT_NEQ;
                3'd4: funct = `FUNCT_LT;
                3'd5: funct = `FUNCT_GTE;
                3'd6: funct = `FUNCT_LTU;
                3'd7: funct = `FUNCT_GTEU;
            endcase
        end
        `OPCODE_STORE: begin
            inst_type = `INST_TYPE_STORE;
            decode_s_type(inst);
            case(funct3)
                3'd2: funct = `FUNCT_MEM_WORD;
                3'd1: funct = `FUNCT_MEM_HWORD;
                3'd0: funct = `FUNCT_MEM_BYTE;
            endcase
        end
    endcase
end
task decode_u_type;
input [`INST_WIDTH-1:0] inst;
begin
    imm = {inst[31:12], 12'b0};
    rd = inst[11:7];
end
endtask
task decode_j_type;
input [`INST_WIDTH-1:0] inst;
begin
    imm = {{11{inst[31]}}, inst[19:12], inst[20], inst[30:25], inst[24:21], 1'b0};
    rd = inst[11:7];
end
endtask
task decode_i_type;
input [`INST_WIDTH-1:0] inst;
begin
    imm = {{21{inst[31]}}, inst[30:20]};
    rd = inst[11:7];
    rs1 = inst[19:15];
    funct3 = inst[14:12];
end
endtask
task decode_r_type;
input [`INST_WIDTH-1:0] inst;
begin
    rs1 = inst[19:15];
    rs2 = inst[24:20];
    rd = inst[11:7];
    funct7 = inst[31:25];
    funct3 = inst[14:12];
end
endtask
task decode_b_type;
input [`INST_WIDTH-1:0] inst;
begin
    imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    rs1 = inst[19:15];
    rs2 = inst[24:20];
    funct3 = inst[14:12];
end
endtask
task decode_s_type;
input [`INST_WIDTH-1:0] inst;
begin
    imm = {{19{inst[31]}}, inst[30:25], inst[11:7]};
    rs1 = inst[19:15];
    rs2 = inst[24:20];
    funct3 = inst[14:12];
end
endtask
endmodule
