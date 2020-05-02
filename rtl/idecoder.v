module idecoder #(
    parameter inst_width = 32,
    parameter opcode_width = 7,
    parameter imm_width = 32,
    parameter reg_width = 5,
    parameter funct_width = 4
) (
    input [inst_width-1:0] inst,
    output [opcode_width-1:0] opcode,
    output [imm_width-1:0] imm,
    output [`INST_TYPE_WIDTH-1:0] inst_type,
    output [reg_width-1:0] rd,
    output [reg_width-1:0] rs1,
    output [reg_width-1:0] rs2,
    output [funct_width-1:0] funct
);
reg [`INST_TYPE_WIDTH-1:0] inst_type;
reg [imm_width-1:0] imm;
reg [opcode_width-1:0] opcode;
reg [funct_width-1:0] funct;
reg [reg_width-1:0] rd;
reg [reg_width-1:0] rs1;
reg [reg_width-1:0] rs2;
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
