`timescale 1ns/1ps
`default_nettype none

`define SIGNED(x,wlhs,high,low)   {{(wlhs-(high-low+1)){x[high]}},x[high:low]}
`define UNSIGNED(x,wlhs,high,low) {{(wlhs-(high-low+1)){1'b0}},x[high:low]}

module copperv (
  input clk,
  input rst,
  wishbone_if.master data_if, 
  wishbone_if.master inst_if
);
parameter pc_init = 0;
parameter data_width     = 32;
parameter pc_width       = 32;
parameter bus_width      = 32;
parameter bus_resp_width = 1;
parameter funct3_width   = 3;
parameter funct7_width   = 7;
parameter reg_width         = 5;
parameter reg_t3            = 28;
parameter alu_shift_din2_width = 5;
parameter inst_width        = 32;
parameter imm_width         = 32;

// idecoder begin
wire [imm_width-1:0] imm;
funct_e funct;
alu_op_e alu_op;
wire [reg_width-1:0] rd;
wire [reg_width-1:0] rs1;
wire [reg_width-1:0] rs2;
inst_type_e inst_type;
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
alu_comp_e alu_comp;
// arith_logic_unit end
// datapath begin
wire inst_fetch;
reg pc_en;
reg [pc_width-1:0] pc;
reg [pc_width-1:0] pc_next;
reg [inst_width-1:0] inst;
reg inst_valid;
wire i_rdata_tran;
rd_din_sel_e rd_din_sel;
pc_next_sel_e pc_next_sel;
alu_din1_sel_e alu_din1_sel;
alu_din2_sel_e alu_din2_sel;
wire store_data;
wire load_data;
wire [data_width-1:0] write_addr;
reg [data_width-1:0] write_data;
reg [data_width-1:0] read_data;
reg [data_width-1:0] ext_read_data;
reg [data_width-1:0] read_data_t;
reg write_valid;
reg alu_shift_din2;
reg read_valid;
wire [bus_width-1:0] read_addr;
reg [2-1:0] write_offset;
reg [2-1:0] read_offset;
reg [(bus_width/8)-1:0] write_strobe;
// datapath end
always @(posedge clk) begin
    if (rst) begin
        pc <= pc_init;
    end else if(pc_en) begin
        pc <= pc_next;
    end
end
assign inst_if.stb = inst_fetch;
assign inst_if.we = 0;
assign inst_if.adr = pc;
assign inst_if.sel = 4'b1111;
always @(posedge clk) begin
    if(rst) begin
        inst_if.cyc <= 0;
    end else if(inst_fetch) begin
        inst_if.cyc <= 1;
    end else if(inst_if.ack) begin
        inst_if.cyc <= 0;
    end
end
always @(posedge clk) begin
    if(rst) begin
        inst_valid <= 0;
    end else if(inst_if.ack) begin
        inst <= inst_if.datrd;
        inst_valid <= 1;
    end else begin
        inst_valid <= 0;
    end
end
// Data bus:
assign read_addr = alu_dout;
assign write_addr = alu_dout;
always @(posedge clk) begin
  if(rst) begin
    data_if.stb <= 0;
    data_if.we <= 0;
  end else if(store_data) begin
    data_if.adr <= {write_addr[data_width-1:2],2'b0};
    data_if.datwr <= write_data;
    data_if.sel <= write_strobe;
    data_if.stb <= 1;
    data_if.we <= 1;
  end else if(load_data) begin
    data_if.adr <= {read_addr[data_width-1:2],2'b0};
    data_if.sel <= 4'b1111;
    data_if.stb <= 1;
    data_if.we <= 0;
  end else
    data_if.stb <= 0;
    data_if.we <= 0;
end
reg past_we;
always @(posedge clk) begin
  past_we <= data_if.we;
  if(load_data)
    read_offset <= read_addr[1:0];
end
always @(posedge clk) begin
  if(rst) begin
    read_data <= 0;
    read_valid <= 0;
  end else if(data_if.ack && !past_we) begin
    read_data <= data_if.datrd;
    read_valid <= 1;
  end else begin
    read_valid <= 0;
  end
end
always @(posedge clk) begin
  if(rst) begin
    write_valid <= 0;
  end else if(data_if.ack && past_we) begin
    write_valid <= 1;
  end else
    write_valid <= 0;
end
always @(*) begin
    write_offset = write_addr[1:0];
    case(funct)
        funct_mem_byte: begin
            write_strobe = 4'b0001 << write_offset;
            write_data   = `UNSIGNED(rs2_dout,32,7,0) << {write_offset, 3'b0};
        end
        funct_mem_hword: begin
            write_strobe = 4'b0011 << write_offset;
            write_data   = `UNSIGNED(rs2_dout,32,15,0) << {write_offset, 3'b0};
        end
        funct_mem_word: begin
            write_strobe = 4'b1111;
            write_data   = rs2_dout;
        end
        default: begin
            write_strobe = 0;
            write_data   = {data_width{1'bx}};
        end
    endcase
end
always @(*) begin
    // TODO: check alignment, ex: if funct == FUNCT_MEM_WORD && read_offset != 0 -> error
    read_data_t = read_data >> {read_offset, 3'b0};
    case(funct)
        funct_mem_byte:   ext_read_data = `SIGNED(read_data_t,32,7,0);
        funct_mem_hword:  ext_read_data = `SIGNED(read_data_t,32,15,0);
        funct_mem_word:   ext_read_data = read_data_t;
        funct_mem_byteu:  ext_read_data = `UNSIGNED(read_data_t,32,7,0);
        funct_mem_hwordu: ext_read_data = `UNSIGNED(read_data_t,32,15,0);
        default:           ext_read_data = {data_width{1'bx}};
    endcase
end
always @(*) begin
    rd_din = 0;
    case(rd_din_sel)
        rd_din_sel_imm: rd_din = imm;
        rd_din_sel_alu: rd_din = alu_dout;
        rd_din_sel_mem: rd_din = ext_read_data;
    endcase
end
always @(*) begin
    alu_din1 = 0;
    case (alu_din1_sel)
        alu_din1_sel_rs1: alu_din1 = rs1_dout;
        alu_din1_sel_pc:  alu_din1 = pc;
    endcase
end
always @(*) begin
    alu_din2 = 0;
    case (alu_din2_sel)
        alu_din2_sel_rs2:     alu_din2 = rs2_dout;
        alu_din2_sel_imm:     alu_din2 = imm;
        alu_din2_sel_const_4: alu_din2 = 4;
    endcase
    if (alu_shift_din2)
      alu_din2 = alu_din2[alu_shift_din2_width-1:0];
end
always @(*) begin
    pc_next = 0;
    pc_en = 1;
    case (pc_next_sel)
        pc_next_sel_stall:       pc_en = 0;
        pc_next_sel_incr:        pc_next = pc + 4;
        pc_next_sel_add_imm:     pc_next = pc + imm;
        pc_next_sel_add_rs1_imm: pc_next = rs1_dout + imm;
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
    .data_valid(write_valid || read_valid),
    .*
);
endmodule

