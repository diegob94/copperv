`timescale 1ns/1ps
`include "copperv_h.v"

module copperv #(
    parameter pc_init = 0
) (
    input clk,
    input rst,
    input d_rdata_valid,
    input d_raddr_ready,
    input d_w_ready,
    input [`BUS_WIDTH-1:0] d_rdata,
    input i_rdata_valid,
    input i_raddr_ready,
    input i_w_ready,
    input [`BUS_WIDTH-1:0] i_rdata,
    output d_rdata_ready,
    output d_raddr_valid,
    output reg d_w_valid,
    output [`BUS_WIDTH-1:0] d_raddr,
    output reg [`BUS_WIDTH-1:0] d_wdata,
    output reg [`BUS_WIDTH-1:0] d_waddr,
    output i_rdata_ready,
    output i_raddr_valid,
    output i_w_valid,
    output [`BUS_WIDTH-1:0] i_raddr,
    output [`BUS_WIDTH-1:0] i_wdata,
    output [`BUS_WIDTH-1:0] i_waddr
);
// idecoder begin
wire [`IMM_WIDTH-1:0] imm;
wire [`OPCODE_WIDTH-1:0] opcode;
wire [`FUNCT_WIDTH-1:0] funct;
wire [`ALU_OP_WIDTH-1:0] alu_op;
wire [`REG_WIDTH-1:0] rd;
wire [`REG_WIDTH-1:0] rs1;
wire [`REG_WIDTH-1:0] rs2;
wire [`INST_TYPE_WIDTH-1:0] inst_type;
// idecoder end
// register_file begin
wire rd_en;
wire rs1_en;
wire rs2_en;
reg [`DATA_WIDTH-1:0] rd_din;
wire [`DATA_WIDTH-1:0] rs1_dout;
wire [`DATA_WIDTH-1:0] rs2_dout;
// register_file end
// arith_logic_unit begin
reg [`DATA_WIDTH-1:0] alu_din1;
reg [`DATA_WIDTH-1:0] alu_din2;
wire [`DATA_WIDTH-1:0] alu_dout;
wire alu_comp;
// arith_logic_unit end
// datapath begin
wire inst_fetch;
reg pc_en;
reg [`PC_WIDTH-1:0] pc;
reg [`PC_WIDTH-1:0] pc_next;
reg [`INST_WIDTH-1:0] inst;
reg inst_valid;
reg i_rdata_tran;
wire [`RD_DIN_SEL_WIDTH-1:0] rd_din_sel;
wire [`PC_NEXT_SEL_WIDTH-1:0] pc_next_sel;
wire [`ALU_DIN1_SEL_WIDTH-1:0] alu_din1_sel;
wire [`ALU_DIN2_SEL_WIDTH-1:0] alu_din2_sel;
reg data_send;
reg data_send_delay;
reg [`DATA_WIDTH-1:0] data_addr;
reg [`DATA_WIDTH-1:0] data_data;
reg d_w_tran;
// datapath end

assign i_rdata_ready = 1;
always @(posedge clk) begin
    if (!rst) begin
        pc <= pc_init;
    end else if(pc_en) begin
        pc <= pc_next;
    end
end
assign i_raddr_valid = inst_fetch;
assign i_raddr = pc;
always @(*) begin
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
always @(posedge clk)
        data_send_delay <= data_send;
always @(*) begin
    data_addr = alu_dout;
    data_data = rs2_dout;
    d_w_valid = data_send && data_send_delay;
    d_w_tran = d_w_valid && d_w_ready;
end
always @(posedge clk) begin
    if(!rst) begin
        d_waddr = 0;
    end else if(d_w_tran) begin
        d_waddr = data_addr;
        d_wdata = data_data;
    end
end
always @(*) begin
    rd_din = 0;
    case (rd_din_sel)
        `RD_DIN_SEL_IMM: rd_din = imm;
        `RD_DIN_SEL_ALU: rd_din = alu_dout;
    endcase
end
always @(*) begin
    alu_din1 = 0;
    case (alu_din1_sel)
        `ALU_DIN1_SEL_RS1: alu_din1 = rs1_dout;
    endcase
end
always @(*) begin
    alu_din2 = 0;
    case (alu_din2_sel)
        `ALU_DIN2_SEL_RS2: alu_din2 = rs2_dout;
        `ALU_DIN2_SEL_IMM: alu_din2 = imm;
    endcase
end
always @(*) begin
    pc_next = 0;
    pc_en = 1;
    case (pc_next_sel)
        `PC_NEXT_SEL_STALL: pc_en = 0;
        `PC_NEXT_SEL_INCR: pc_next = pc + 4;
        `PC_NEXT_SEL_BRANCH: pc_next = pc + imm;
    endcase
end
idecoder idec (
    .inst(inst),
    .opcode(opcode),
    .imm(imm),
    .inst_type(inst_type),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .funct(funct)
);
register_file regfile (
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
arith_logic_unit alu (
    .alu_din1(alu_din1),
    .alu_din2(alu_din2),
    .alu_op(alu_op),
    .alu_dout(alu_dout),
    .alu_comp(alu_comp)
);
control_unit control (
    .clk(clk),
    .rst(rst),
    .inst_valid(inst_valid),
    .alu_comp(alu_comp),
    .funct(funct),
    .inst_type(inst_type),
    .inst_fetch(inst_fetch),
    .rd_en(rd_en),
    .rs1_en(rs1_en),
    .rs2_en(rs2_en),
    .rd_din_sel(rd_din_sel),
    .pc_next_sel(pc_next_sel),
    .alu_din1_sel(alu_din1_sel),
    .alu_din2_sel(alu_din2_sel),
    .alu_op(alu_op)
);
endmodule

