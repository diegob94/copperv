`default_nettype none

module copperv #(
    parameter bus_width = 32,
    parameter pc_width = 32,
    parameter pc_init = 0,
    parameter inst_width = 32,
    parameter opcode_width = 7,
    parameter imm_width = 32,
    parameter data_width = 32,
    parameter reg_width = 5,
    parameter funct_width = 4
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
// idecoder begin
wire [imm_width-1:0] imm;
wire [opcode_width-1:0] opcode;
wire [funct_width-1:0] funct;
wire [reg_width-1:0] rd;
wire [reg_width-1:0] rs1;
wire [reg_width-1:0] rs2;
wire type_int_imm;
wire type_imm;
wire type_int_reg;
wire type_branch;
// idecoder end
// register_file begin
reg rd_en;
reg rs1_en;
reg rs2_en;
reg [data_width-1:0] rd_din;
wire [data_width-1:0] rs1_dout;
wire [data_width-1:0] rs2_dout;
// register_file end
// arith_logic_unit begin
reg [data_width-1:0] alu_din1;
reg [data_width-1:0] alu_din2;
wire [data_width-1:0] alu_dout;
// arith_logic_unit end
reg [data_width-1:0] exreg;
reg exreg_en;
reg inst_fetch;
reg [pc_width-1:0] pc;
reg [pc_width-1:0] pc_next;
reg [inst_width-1:0] inst;
reg inst_valid;
reg i_rdata_tran;
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
    .imm_width(imm_width),
    .reg_width(reg_width),
    .funct_width(funct_width)
) idec (
    .inst(inst),
    .opcode(opcode),
    .imm(imm),
    .type_imm(type_imm),
    .type_int_imm(type_int_imm),
    .type_int_reg(type_int_reg),
    .type_branch(type_branch),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .funct(funct)
);
always @(*) begin
    rd_en = 0;
    rs1_en = 0;
    rs2_en = 0;
    rd_din = 0;
    exreg_en = 0;
    if(inst_valid) begin
        if(type_imm) begin
            rd_en = 1;
            rd_din = imm;
        end else if(type_int_imm) begin
            rs1_en = 1;
            alu_din1 = rs1_dout;
            alu_din2 = imm;
            exreg_en = 1;
        end
    end
end
always @(posedge clk) begin
    if(exreg_en) begin
        exreg <= alu_dout;
    end
end
register_file #(
    .reg_width(reg_width),
    .data_width(data_width)
) regfile (
    .clk(clk),
    .rd_en(rd_en),
    .rs1_en(rs1_en),
    .rs2_en(rs2_en),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .rd_din(rd_din),
    .rs1_dout(rs1_dout),
    .rs2_dout(rs2_dout)
);
arith_logic_unit #(
    .data_width(data_width),
    .funct_width(funct_width)
) alu (
    .alu_din1(alu_din1),
    .alu_din2(alu_din2),
    .funct(funct),
    .alu_dout(alu_dout)
);
endmodule

