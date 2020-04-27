`default_nettype none

module copperv #(
    parameter bus_width = 32,
    parameter pc_width = 32,
    parameter pc_init = 0,
    parameter inst_width = 32,
    parameter opcode_width = 7,
    parameter imm_width = 32
) (
    input clk,
    input rst,
    input d_rdata_valid,
    input d_raddr_ready,
    input d_wdata_ready,
    input d_waddr_ready,
    input [bus_width-1:0] d_rdata,
    input i_rdata_valid,
    input i_raddr_ready,
    input i_wdata_ready,
    input i_waddr_ready,
    input [bus_width-1:0] i_rdata,
    output d_rdata_ready,
    output d_raddr_valid,
    output d_wdata_valid,
    output d_waddr_valid,
    output [bus_width-1:0] d_raddr,
    output [bus_width-1:0] d_wdata,
    output [bus_width-1:0] d_waddr,
    output i_rdata_ready,
    output i_raddr_valid,
    output i_wdata_valid,
    output i_waddr_valid,
    output [bus_width-1:0] i_raddr,
    output [bus_width-1:0] i_wdata,
    output [bus_width-1:0] i_waddr
);
reg inst_fetch;
reg [pc_width-1:0] pc;
reg [pc_width-1:0] pc_next;
reg [inst_width-1:0] inst;
reg inst_valid;
reg i_rdata_tran;
wire [opcode_width-1:0] opcode;
wire [imm_width-1:0] imm;
assign i_rdata_ready = 1;
always @(posedge clk) begin
    if (!rst) begin
        pc <= pc_init;
        inst_fetch <= 1;
    end else begin
        pc <= pc_next;
    end
end
assign i_raddr_valid = inst_fetch;
assign i_raddr = pc;
always @(*) begin
    pc_next = pc + 4;
    i_rdata_tran = i_rdata_valid && i_rdata_ready;
end
always @(posedge clk) begin
    if(!rst) begin
        inst <= 0;
        inst_valid <= 0;
    end else if(i_rdata_tran) begin
        inst <= i_rdata;
        inst_valid <= 1;
    end else begin
        inst_valid <= 0;
    end
end
idecoder #(
    .inst_width(inst_width),
    .opcode_width(opcode_width),
    .imm_width(imm_width)
) idec (
    .inst(inst),
    .opcode(opcode)
);
endmodule

module idecoder #(
    parameter inst_width = 32,
    parameter opcode_width = 7,
    parameter imm_width = 32
) (
    input [inst_width-1:0] inst,
    output [opcode_width-1:0] opcode,
    output [imm_width-1:0] imm,
    output type_int_imm,
    output type_int,
    output type_branch
);
reg [imm_width-1:0] imm;
reg [opcode_width-1:0] opcode;
reg [4-1:0] funct;
reg type_int_imm;
reg type_int;
reg type_branch;
always @(*) begin
    opcode = inst[6:0];
    funct = {1'b0, inst[14:12]};
    imm = 0;
    type_int_imm = 0;
    type_int = 0;
    type_branch = 0;
    case (opcode)
        {6'h0D, 2'b11}: imm = {inst[31:12], 12'b0};
        {6'h04, 2'b11}: begin
            type_int_imm = 1;
            imm = {{21{inst[31]}}, inst[30:20]};
        end
        {6'h0C, 2'b11}: begin
            type_int = 1;
            funct[3] = inst[31:25] == 7'd32 ? 1 : 0;
        end
        {6'h18, 2'b11}: begin
            type_branch = 1;
            imm = {{19{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
        end
    endcase
/*
    if (int_imm) begin
        case (funct3)
            2'b00: 
        endcase
    end
*/
end
endmodule

