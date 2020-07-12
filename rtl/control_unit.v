`timescale 1ns/1ps
`include "copperv_h.v"

module control_unit ( 
    input clk,
    input rst,
    input [`INST_TYPE_WIDTH-1:0] inst_type,
    input inst_valid,
    input [`ALU_COMP_WIDTH-1:0] alu_comp,
    input [`FUNCT_WIDTH-1:0] funct,
    input data_valid,
    output reg inst_fetch,
    output reg store_data,
    output reg load_data,
    output reg rd_en,
    output reg rs1_en,
    output reg rs2_en,
    output reg [`RD_DIN_SEL_WIDTH-1:0] rd_din_sel,
    output reg [`PC_NEXT_SEL_WIDTH-1:0] pc_next_sel,
    output reg [`ALU_DIN1_SEL_WIDTH-1:0] alu_din1_sel,
    output reg [`ALU_DIN2_SEL_WIDTH-1:0] alu_din2_sel,
    output reg [`ALU_OP_WIDTH-1:0] alu_op
);
reg [`STATE_WIDTH-1:0] state;
reg [`STATE_WIDTH-1:0] state_next;
reg state_change;
reg take_branch;
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
                    `INST_TYPE_JAL:   state_next = `STATE_EXEC;
                    default:          state_next = `STATE_DECODE;
                endcase
            else
                state_next = `STATE_FETCH;
        end
        `STATE_DECODE: begin
            case (inst_type)
                `INST_TYPE_IMM:   state_next = `STATE_FETCH;
                `INST_TYPE_FENCE: state_next = `STATE_FETCH;
                default:          state_next = `STATE_EXEC;
            endcase
        end
        `STATE_EXEC: begin
            case (inst_type)
                `INST_TYPE_STORE: state_next = `STATE_MEM;
                `INST_TYPE_LOAD:  state_next = `STATE_MEM;
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
    load_data = 0;
    take_branch = 0;
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
                `INST_TYPE_LOAD: begin
                    rs1_en = 1;
                end
                `INST_TYPE_JALR: begin
                    rs1_en = 1;
                end
                `INST_TYPE_FENCE: begin
                    pc_next_sel = `PC_NEXT_SEL_INCR;
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
                    alu_op = get_int_alu_op(funct);
                end
                `INST_TYPE_INT_REG: begin
                    rd_en = 1;
                    rd_din_sel = `RD_DIN_SEL_ALU;
                    alu_din1_sel = `ALU_DIN1_SEL_RS1;
                    alu_din2_sel = `ALU_DIN2_SEL_RS2;
                    pc_next_sel = `PC_NEXT_SEL_INCR;
                    alu_op = get_int_alu_op(funct);
                end
                `INST_TYPE_BRANCH: begin
                    alu_din1_sel = `ALU_DIN1_SEL_RS1;
                    alu_din2_sel = `ALU_DIN2_SEL_RS2;
                    case(funct)
                        `FUNCT_EQ:
                            take_branch =  alu_comp[`ALU_COMP_EQ];
                        `FUNCT_NEQ:
                            take_branch = !alu_comp[`ALU_COMP_EQ];
                        `FUNCT_LT:
                            take_branch =  alu_comp[`ALU_COMP_LT];
                        `FUNCT_GTE:
                            take_branch = !alu_comp[`ALU_COMP_LT];
                        `FUNCT_LTU:
                            take_branch =  alu_comp[`ALU_COMP_LTU];
                        `FUNCT_GTEU:
                            take_branch = !alu_comp[`ALU_COMP_LTU];
                    endcase
                    if(take_branch)
                        pc_next_sel = `PC_NEXT_SEL_ADD_IMM;
                    else
                        pc_next_sel = `PC_NEXT_SEL_INCR;
                end
                `INST_TYPE_STORE: begin
                    alu_din1_sel = `ALU_DIN1_SEL_RS1;
                    alu_din2_sel = `ALU_DIN2_SEL_IMM;
                    alu_op = `ALU_OP_ADD;
                    store_data = state_change;
                end
                `INST_TYPE_LOAD: begin
                    alu_din1_sel = `ALU_DIN1_SEL_RS1;
                    alu_din2_sel = `ALU_DIN2_SEL_IMM;
                    alu_op = `ALU_OP_ADD;
                    load_data = state_change;
                end
                `INST_TYPE_JAL: begin
                    rd_en = 1;
                    rd_din_sel = `RD_DIN_SEL_ALU;
                    alu_din1_sel = `ALU_DIN1_SEL_PC;
                    alu_din2_sel = `ALU_DIN2_SEL_CONST_4;
                    pc_next_sel = `PC_NEXT_SEL_ADD_IMM;
                    alu_op = `ALU_OP_ADD;
                end
                `INST_TYPE_AUIPC: begin
                    rd_en = 1;
                    rd_din_sel = `RD_DIN_SEL_ALU;
                    alu_din1_sel = `ALU_DIN1_SEL_PC;
                    alu_din2_sel = `ALU_DIN2_SEL_IMM;
                    pc_next_sel = `PC_NEXT_SEL_INCR;
                    alu_op = `ALU_OP_ADD;
                end
                `INST_TYPE_JALR: begin
                    rd_en = 1;
                    rd_din_sel = `RD_DIN_SEL_ALU;
                    alu_din1_sel = `ALU_DIN1_SEL_PC;
                    alu_din2_sel = `ALU_DIN2_SEL_CONST_4;
                    pc_next_sel = `PC_NEXT_SEL_ADD_RS1_IMM;
                    alu_op = `ALU_OP_ADD;
                end
            endcase
        end
        `STATE_MEM: begin
            if(inst_type == `INST_TYPE_LOAD) begin
                rd_en = state_change_next;
                rd_din_sel = `RD_DIN_SEL_MEM;
            end
            if(state_change_next)
                pc_next_sel = `PC_NEXT_SEL_INCR;
        end
    endcase
end
function [`ALU_OP_WIDTH-1:0] get_int_alu_op;
    input [`FUNCT_WIDTH-1:0] funct;
    begin
        case(funct)
            `FUNCT_ADD:  get_int_alu_op = `ALU_OP_ADD;
            `FUNCT_SUB:  get_int_alu_op = `ALU_OP_SUB;
            `FUNCT_SLL:  get_int_alu_op = `ALU_OP_SLL;
            `FUNCT_SLT:  get_int_alu_op = `ALU_OP_SLT;
            `FUNCT_SLTU: get_int_alu_op = `ALU_OP_SLTU;
            `FUNCT_XOR:  get_int_alu_op = `ALU_OP_XOR;
            `FUNCT_SRL:  get_int_alu_op = `ALU_OP_SRL;
            `FUNCT_SRA:  get_int_alu_op = `ALU_OP_SRA;
            `FUNCT_OR:   get_int_alu_op = `ALU_OP_OR;
            `FUNCT_AND:  get_int_alu_op = `ALU_OP_AND;
            default:     get_int_alu_op = `ALU_OP_NOP;
        endcase
    end
endfunction
endmodule
