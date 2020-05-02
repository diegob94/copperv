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
    parameter funct_width = 4,
    parameter rd_din_sel_width = 1
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
wire [`INST_TYPE_WIDTH-1:0] inst_type;
// idecoder end
// register_file begin
wire rd_en;
wire rs1_en;
wire rs2_en;
reg [data_width-1:0] rd_din;
wire [data_width-1:0] rs1_dout;
wire [data_width-1:0] rs2_dout;
// register_file end
// arith_logic_unit begin
reg [data_width-1:0] alu_din1;
reg [data_width-1:0] alu_din2;
wire [data_width-1:0] alu_dout;
// arith_logic_unit end
wire inst_fetch;
reg [pc_width-1:0] pc;
reg [pc_width-1:0] pc_next;
reg [inst_width-1:0] inst;
reg inst_valid;
reg i_rdata_tran;
wire [`RD_DIN_SEL_WIDTH-1:0] rd_din_sel;
assign i_rdata_ready = 1;
always @(posedge clk) begin
    if (!rst) begin
        pc <= pc_init;
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
    .inst_type(inst_type),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .funct(funct)
);
parameter RD_DIN_SEL_IMM = 0;
always @(*) begin
    rd_din = 0;
    case (rd_din_sel)
        RD_DIN_SEL_IMM: rd_din = imm;
    endcase
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
control_unit #(
    .rd_din_sel_width(rd_din_sel_width)
) control (
    .clk(clk),
    .rst(rst),
    .inst_type(inst_type),
    .inst_fetch(inst_fetch),
    .rd_en(rd_en),
    .rs1_en(rs1_en),
    .rs2_en(rs2_en),
    .rd_din_sel(rd_din_sel)
);
endmodule

