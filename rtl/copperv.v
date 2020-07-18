`timescale 1ns/1ps
`include "copperv_h.v"

module copperv #(
    parameter pc_init = 0
) (
    input clk,
    input rst,
    input ir_data_valid,
    input ir_addr_ready,
    input [`BUS_WIDTH-1:0] ir_data,
    input dr_data_valid,
    input dr_addr_ready,
    input dw_data_addr_ready,
    input dw_resp_valid,
    input [`BUS_WIDTH-1:0] dr_data,
    input [`BUS_RESP_WIDTH-1:0] dw_resp,
    output reg ir_data_ready,
    output ir_addr_valid,
    output [`BUS_WIDTH-1:0] ir_addr,
    output reg dr_data_ready,
    output reg dr_addr_valid,
    output reg dw_data_addr_valid,
    output reg dw_resp_ready,
    output reg [`BUS_WIDTH-1:0] dr_addr,
    output reg [`BUS_WIDTH-1:0] dw_data,
    output reg [`BUS_WIDTH-1:0] dw_addr,
    output reg [(`BUS_WIDTH/8)-1:0] dw_strobe
);
// idecoder begin
wire [`IMM_WIDTH-1:0] imm;
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
wire [`ALU_COMP_WIDTH-1:0] alu_comp;
// arith_logic_unit end
// datapath begin
wire inst_fetch;
reg pc_en;
reg [`PC_WIDTH-1:0] pc;
reg [`PC_WIDTH-1:0] pc_next;
reg [`INST_WIDTH-1:0] inst;
reg inst_valid;
wire i_rdata_tran;
wire [`RD_DIN_SEL_WIDTH-1:0] rd_din_sel;
wire [`PC_NEXT_SEL_WIDTH-1:0] pc_next_sel;
wire [`ALU_DIN1_SEL_WIDTH-1:0] alu_din1_sel;
wire [`ALU_DIN2_SEL_WIDTH-1:0] alu_din2_sel;
wire store_data;
wire load_data;
reg [`DATA_WIDTH-1:0] write_addr;
reg [`DATA_WIDTH-1:0] write_data;
reg [`DATA_WIDTH-1:0] read_data;
reg [`DATA_WIDTH-1:0] ext_read_data;
reg [`DATA_WIDTH-1:0] read_data_t;
reg write_valid;
wire dw_resp_tran;
reg dw_data_addr_tran;
reg dr_addr_tran;
reg read_valid;
wire [`BUS_WIDTH-1:0] read_addr;
reg [2-1:0] write_offset;
reg [2-1:0] read_offset;
wire dr_data_tran;
reg [(`BUS_WIDTH/8)-1:0] write_strobe;
// datapath end
always @(posedge clk) begin
    if (!rst) begin
        pc <= pc_init;
    end else if(pc_en) begin
        pc <= pc_next;
    end
end
assign ir_addr_valid = inst_fetch;
assign ir_addr = pc;
assign i_rdata_tran = ir_data_valid && ir_data_ready;
always @(posedge clk) begin
    if(!rst) begin
        inst <= 0;
        inst_valid <= 0;
    end else if(i_rdata_tran) begin
        inst <= ir_data;
        inst_valid <= 1;
    end else begin
        inst_valid <= 0;
    end
end
// Write response
assign dw_resp_tran = dw_resp_valid && dw_resp_ready;
always @(posedge clk) begin
    if(!rst) begin
        write_valid <= 0;
    end else if(dw_resp_tran) begin
        case(dw_resp)
            `DATA_WRITE_RESP_FAIL: write_valid <= 0;
            `DATA_WRITE_RESP_OK: write_valid <= 1;
        endcase
    end else
        write_valid <= 0;
end
always @(posedge clk)
    if(!rst) begin
        ir_data_ready <= 1;
    end
// Write data address
assign write_addr = alu_dout;
assign dw_data_addr_tran = store_data && dw_data_addr_ready;
always @(posedge clk) begin
    if(!rst) begin
        dw_addr <= 0;
        dw_data <= 0;
        dw_strobe <= 0;
        dw_data_addr_valid <= 0;
    end else if(dw_data_addr_tran) begin
        dw_addr <= {write_addr[`DATA_WIDTH-1:2],2'b0};
        dw_data <= write_data;
        dw_strobe <= write_strobe;
        dw_data_addr_valid <= 1;
    end else
        dw_data_addr_valid <= 0;
end
always @(posedge clk)
    if(!rst) begin
        dw_resp_ready <= 1;
    end
// Read address
assign read_addr = alu_dout;
assign dr_addr_tran = load_data && dr_addr_ready;
always @(posedge clk) begin
    if(load_data)
        read_offset <= read_addr[1:0];
end
always @(posedge clk) begin
    if(!rst) begin
        dr_addr <= 0;
        dr_addr_valid <= 0;
    end else if(dr_addr_tran) begin
        dr_addr <= {read_addr[`DATA_WIDTH-1:2],2'b0};
        dr_addr_valid <= 1;
    end else
        dr_addr_valid <= 0;
end
// Read data
assign dr_data_tran = dr_data_valid && dr_data_ready;
always @(posedge clk) begin
    if(!rst) begin
        read_data <= 0;
        read_valid <= 0;
    end else if(dr_data_tran) begin
        read_data <= dr_data;
        read_valid <= 1;
    end else begin
        read_valid <= 0;
    end
end
always @(posedge clk) begin
    if(!rst) begin
        dr_data_ready <= 1;
    end
end
always @(*) begin
    write_offset = write_addr[1:0];
    case(funct)
        `FUNCT_MEM_BYTE: begin
            write_strobe = 4'b0001 << write_offset;
            write_data   = rs2_dout[7:0] << {write_offset, 3'b0};
        end
        `FUNCT_MEM_HWORD: begin
            write_strobe = 4'b0011 << write_offset;
            write_data   = rs2_dout[15:0] << {write_offset, 3'b0};
        end
        `FUNCT_MEM_WORD: begin
            write_strobe = 4'b1111;
            write_data   = rs2_dout;
        end
        default: begin
            write_strobe = 0;
            write_data   = {`DATA_WIDTH{1'bX}};
        end
    endcase
end
always @(*) begin
    read_data_t = read_data >> {read_offset, 3'b0};
    case(funct)
        `FUNCT_MEM_BYTE:   ext_read_data = `SIGNED(read_data_t,32,7,0);
        `FUNCT_MEM_HWORD:  ext_read_data = `SIGNED(read_data_t,32,15,0);
        `FUNCT_MEM_WORD:   ext_read_data = read_data_t;
        `FUNCT_MEM_BYTEU:  ext_read_data = `UNSIGNED(read_data_t,32,7,0);
        `FUNCT_MEM_HWORDU: ext_read_data = `UNSIGNED(read_data_t,32,15,0);
        default:           ext_read_data = {`DATA_WIDTH{1'bX}};
    endcase
end
always @(*) begin
    rd_din = 0;
    case(rd_din_sel)
        `RD_DIN_SEL_IMM: rd_din = imm;
        `RD_DIN_SEL_ALU: rd_din = alu_dout;
        `RD_DIN_SEL_MEM: rd_din = ext_read_data;
    endcase
end
always @(*) begin
    alu_din1 = 0;
    case (alu_din1_sel)
        `ALU_DIN1_SEL_RS1: alu_din1 = rs1_dout;
        `ALU_DIN1_SEL_PC:  alu_din1 = pc;
    endcase
end
always @(*) begin
    alu_din2 = 0;
    case (alu_din2_sel)
        `ALU_DIN2_SEL_RS2:     alu_din2 = rs2_dout;
        `ALU_DIN2_SEL_IMM:     alu_din2 = imm;
        `ALU_DIN2_SEL_CONST_4: alu_din2 = 4;
    endcase
end
always @(*) begin
    pc_next = 0;
    pc_en = 1;
    case (pc_next_sel)
        `PC_NEXT_SEL_STALL:       pc_en = 0;
        `PC_NEXT_SEL_INCR:        pc_next = pc + 4;
        `PC_NEXT_SEL_ADD_IMM:     pc_next = pc + imm;
        `PC_NEXT_SEL_ADD_RS1_IMM: pc_next = rs1_dout + imm;
    endcase
end
idecoder idec (
    .inst(inst),
    .imm(imm),
    .inst_type(inst_type),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .funct(funct)
);
register_file regfile (
    .clk(clk),
    .rst(rst),
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
    .data_valid(write_valid || read_valid),
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
    .alu_op(alu_op),
    .store_data(store_data),
    .load_data(load_data)
);
endmodule

