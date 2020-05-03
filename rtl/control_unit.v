`timescale 1ns/1ps
`include "copperv_h.v"

module control_unit ( 
    input clk,
    input rst,
    input [`INST_TYPE_WIDTH-1:0] inst_type,
    input inst_valid,
    output inst_fetch,
    output rd_en,
    output rs1_en,
    output rs2_en,
    output [`RD_DIN_SEL_WIDTH-1:0] rd_din_sel,
    output [`PC_NEXT_SEL_WIDTH-1:0] pc_next_sel,
    output [`ALU_DIN1_SEL_WIDTH-1:0] alu_din1_sel,
    output [`ALU_DIN2_SEL_WIDTH-1:0] alu_din2_sel
);
reg [`STATE_WIDTH-1:0] state;
reg [`STATE_WIDTH-1:0] state_next;
reg inst_fetch;
reg rd_en;
reg rs1_en;
reg rs2_en;
reg [`RD_DIN_SEL_WIDTH-1:0] rd_din_sel;
reg [`PC_NEXT_SEL_WIDTH-1:0] pc_next_sel;
reg [`ALU_DIN1_SEL_WIDTH-1:0] alu_din1_sel;
reg [`ALU_DIN2_SEL_WIDTH-1:0] alu_din2_sel;
always @(posedge clk) begin
    if(!rst)
        state <= `STATE_RESET;
    else
        state <= state_next;
end
// Next state logic
always @(*) begin
    state_next = `STATE_IDLE;
    case (state)
        `STATE_RESET: begin
            state_next = `STATE_FETCH;
        end
        `STATE_IDLE: begin
            if (inst_valid)
                state_next = `STATE_LOAD;
            else
                state_next = `STATE_IDLE;
        end
        `STATE_FETCH: begin
            state_next = `STATE_IDLE;
        end
        `STATE_LOAD: begin
            case (inst_type)
                `INST_TYPE_IMM: state_next = `STATE_FETCH;
                default: state_next = `STATE_EXEC;
            endcase
        end
        `STATE_EXEC: begin
            state_next = `STATE_FETCH;
        end
        `STATE_MEM: begin
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
    case (state)
        `STATE_RESET: begin
            pc_next_sel = `PC_NEXT_SEL_STALL;
        end
        `STATE_IDLE: begin
            pc_next_sel = `PC_NEXT_SEL_STALL;
        end
        `STATE_FETCH: begin
            inst_fetch = 1;
            pc_next_sel = `PC_NEXT_SEL_INCR;
        end
        `STATE_LOAD: begin
            case (inst_type)
                `INST_TYPE_IMM: begin
                    rd_en = 1;
                    rd_din_sel = `RD_DIN_SEL_IMM;
                end
                `INST_TYPE_INT_IMM: begin
                    rs1_en = 1;
                end
                `INST_TYPE_INT_REG: begin
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
                end
                `INST_TYPE_INT_REG: begin
                    rd_en = 1;
                    rd_din_sel = `RD_DIN_SEL_ALU;
                    alu_din1_sel = `ALU_DIN1_SEL_RS1;
                    alu_din2_sel = `ALU_DIN2_SEL_RS2;
                end
            endcase
        end
        `STATE_MEM: begin
        end
    endcase
end
endmodule
