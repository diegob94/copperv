`timescale 1ns/1ps
`include "copperv_h.v"

module control_unit ( 
    input clk,
    input rst,
    input [`INST_TYPE_WIDTH-1:0] inst_type,
    input inst_valid,
    input alu_comp,
    input [`FUNCT_WIDTH-1:0] funct,
    input data_valid,
    output reg inst_fetch,
    output reg store_data,
    output rd_en,
    output rs1_en,
    output rs2_en,
    output [`RD_DIN_SEL_WIDTH-1:0] rd_din_sel,
    output [`PC_NEXT_SEL_WIDTH-1:0] pc_next_sel,
    output [`ALU_DIN1_SEL_WIDTH-1:0] alu_din1_sel,
    output [`ALU_DIN2_SEL_WIDTH-1:0] alu_din2_sel,
    output [`ALU_OP_WIDTH-1:0] alu_op
);
reg [`STATE_WIDTH-1:0] state;
reg [`STATE_WIDTH-1:0] state_next;
reg rd_en;
reg rs1_en;
reg rs2_en;
reg [`RD_DIN_SEL_WIDTH-1:0] rd_din_sel;
reg [`PC_NEXT_SEL_WIDTH-1:0] pc_next_sel;
reg [`ALU_DIN1_SEL_WIDTH-1:0] alu_din1_sel;
reg [`ALU_DIN2_SEL_WIDTH-1:0] alu_din2_sel;
reg [`ALU_OP_WIDTH-1:0] alu_op;
reg state_change;
wire state_change_next;
always @(posedge clk) begin
    if(!rst)
        state <= `STATE_RESET;
    else
        state <= state_next;
end
assign state_change_next = state != state_next;
// TODO: gate possible?
always @(posedge clk) begin
    state_change <= state_change_next;
end
// Next state logic
always @(*) begin
    state_next = `STATE_RESET;
    case (state)
        `STATE_RESET: begin
            state_next = `STATE_FETCH;
        end
        `STATE_FETCH: begin
            if (inst_valid)
                case(inst_type)
                    `INST_TYPE_JAL: state_next = `STATE_EXEC;
                    default: state_next = `STATE_DECODE;
                endcase
            else
                state_next = `STATE_FETCH;
        end
        `STATE_DECODE: begin
            case (inst_type)
                `INST_TYPE_IMM: state_next = `STATE_FETCH;
                default: state_next = `STATE_EXEC;
            endcase
        end
        `STATE_EXEC: begin
            case (inst_type)
                `INST_TYPE_STORE: state_next = `STATE_MEM;
                default: state_next = `STATE_FETCH;
            endcase
        end
        `STATE_MEM: begin
            if (data_valid)
                state_next = `STATE_FETCH;
            else
                state_next = `STATE_MEM;
        end
    endcase
end
// Output logic
always @(*) begin
    inst_fetch = 0;
    rd_en = 0;
    rs1_en = 0;
    rs2_en = 0;
    rd_din_sel = 0;
    alu_din1_sel = 0;
    alu_din2_sel = 0;
    pc_next_sel = `PC_NEXT_SEL_STALL;
    alu_op = `ALU_OP_NOP;
    store_data = 0;
    case (state)
        `STATE_FETCH: begin
            inst_fetch = state_change;
        end
        `STATE_DECODE: begin
            case (inst_type)
                `INST_TYPE_IMM: begin
                    rd_en = 1;
                    rd_din_sel = `RD_DIN_SEL_IMM;
                    pc_next_sel = `PC_NEXT_SEL_INCR;
                end
                `INST_TYPE_INT_IMM: begin
                    rs1_en = 1;
                end
                `INST_TYPE_INT_REG: begin
                    rs1_en = 1;
                    rs2_en = 1;
                end
                `INST_TYPE_BRANCH: begin
                    rs1_en = 1;
                    rs2_en = 1;
                end
                `INST_TYPE_STORE: begin
                    rs1_en = 1;
                    rs2_en = 1;
                end
            endcase
        end
        `STATE_EXEC: begin
            case (inst_type)
                `INST_TYPE_INT_IMM: begin
                    rd_en = 1;
                    rd_din_sel = `RD_DIN_SEL_ALU;
                    alu_din1_sel = `ALU_DIN1_SEL_RS1;
                    alu_din2_sel = `ALU_DIN2_SEL_IMM;
                    pc_next_sel = `PC_NEXT_SEL_INCR;
                    case(funct)
                        `FUNCT_ADD: alu_op = `ALU_OP_ADD;
                        `FUNCT_SUB: alu_op = `ALU_OP_SUB;
                    endcase
                end
                `INST_TYPE_INT_REG: begin
                    rd_en = 1;
                    rd_din_sel = `RD_DIN_SEL_ALU;
                    alu_din1_sel = `ALU_DIN1_SEL_RS1;
                    alu_din2_sel = `ALU_DIN2_SEL_RS2;
                    pc_next_sel = `PC_NEXT_SEL_INCR;
                    case(funct)
                        `FUNCT_ADD: alu_op = `ALU_OP_ADD;
                        `FUNCT_SUB: alu_op = `ALU_OP_SUB;
                    endcase
                end
                `INST_TYPE_BRANCH: begin
                    alu_din1_sel = `ALU_DIN1_SEL_RS1;
                    alu_din2_sel = `ALU_DIN2_SEL_RS2;
                    if(alu_comp)
                        pc_next_sel = `PC_NEXT_SEL_ADD_IMM;
                    else
                        pc_next_sel = `PC_NEXT_SEL_INCR;
                end
                `INST_TYPE_STORE: begin
                    alu_din1_sel = `ALU_DIN1_SEL_RS1;
                    alu_din2_sel = `ALU_DIN2_SEL_IMM;
                    case(funct)
                        `FUNCT_MEM_WORD: alu_op = `ALU_OP_ADD;
                    endcase
                    if(inst_type == `INST_TYPE_STORE)
                        store_data = state_change;
                end
                `INST_TYPE_JAL: begin
                    rd_en = 1;
                    rd_din_sel = `RD_DIN_SEL_ALU;
                    alu_din1_sel = `ALU_DIN1_SEL_PC;
                    alu_din2_sel = `ALU_DIN2_SEL_CONST_4;
                    pc_next_sel = `PC_NEXT_SEL_ADD_IMM;
                    case(funct)
                        `FUNCT_ADD: alu_op = `ALU_OP_ADD;
                    endcase
                end
            endcase
        end
        `STATE_MEM: begin
            if(state_change_next)
                pc_next_sel = `PC_NEXT_SEL_INCR;
        end
    endcase
end
endmodule
