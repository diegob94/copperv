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
    output type_imm,
    output type_int_imm,
    output type_int_reg,
    output type_branch,
    output [reg_width-1:0] rd,
    output [reg_width-1:0] rs1,
    output [reg_width-1:0] rs2,
    output [funct_width-1:0] funct
);
reg [imm_width-1:0] imm;
reg [opcode_width-1:0] opcode;
reg [funct_width-1:0] funct;
reg [reg_width-1:0] rd;
reg [reg_width-1:0] rs1;
reg [reg_width-1:0] rs2;
reg type_int_imm;
reg type_imm;
reg type_int_reg;
reg type_branch;
always @(*) begin
    opcode = inst[6:0];
    imm = 0;
    type_imm = 0;
    type_int_imm = 0;
    type_int_reg = 0;
    type_branch = 0;
    funct = 0;
    rd = 0;
    rs1 = 0;
    rs2 = 0;
    case (opcode)
        {6'h0D, 2'b11}: begin // LUI
            type_imm = 1;
            imm = {inst[31:12], 12'b0};
            rd = inst[11:7];
        end
        {6'h04, 2'b11}: begin // Reg-Inmmediate
            type_int_imm = 1;
            imm = {{21{inst[31]}}, inst[30:20]};
            rd = inst[11:7];
            rs1 = inst[19:15];
            funct = {1'b0, inst[14:12]};
        end
        {6'h0C, 2'b11}: begin // Reg-reg
            type_int_reg = 1;
            rs2 = inst[24:20];
            funct = {inst[31:25] == 7'd32 ? 1'b1 : 1'b0, inst[14:12]};
        end
        {6'h18, 2'b11}: begin
            type_branch = 1;
            imm = {{19{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
        end
    endcase
end
endmodule
