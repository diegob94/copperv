`timescale 1ns/1ps

module control_unit import copperv_pkg::*;
  (
    input clk,
    input rst,
    input inst_type_e inst_type,
    input inst_valid,
    input alu_comp_e alu_comp,
    input funct_e funct,
    input data_valid,
    output reg inst_fetch,
    output reg load_data,
    output reg store_data,
    output reg rd_en,
    output reg rs1_en,
    output reg rs2_en,
    output rd_din_sel_e rd_din_sel,
    output pc_next_sel_e pc_next_sel,
    output alu_din1_sel_e alu_din1_sel,
    output alu_din2_sel_e alu_din2_sel,
    output alu_op_e alu_op,
    output reg alu_shift_din2
  );
  state_e state;
  state_e state_next;
  reg state_change;
  reg take_branch;
  wire state_change_next;
  always @(posedge clk) begin
      if(rst)
          state <= state_reset;
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
      state_next = state_reset;
      case (state)
          state_reset: begin
              state_next = state_fetch;
          end
          state_fetch: begin
              if (inst_valid)
                  case(inst_type)
                      inst_type_jal:   state_next = state_exec;
                      default:          state_next = state_decode;
                  endcase
              else
                  state_next = state_fetch;
          end
          state_decode: begin
              case (inst_type)
                  inst_type_imm:   state_next = state_fetch;
                  inst_type_fence: state_next = state_fetch;
                  default:          state_next = state_exec;
              endcase
          end
          state_exec: begin
              case (inst_type)
                  inst_type_store: state_next = state_mem;
                  inst_type_load:  state_next = state_mem;
                  default: state_next = state_fetch;
              endcase
          end
          state_mem: begin
              if (data_valid)
                  state_next = state_fetch;
              else
                  state_next = state_mem;
          end
      endcase
  end
  // Output logic
  always @(*) begin
      inst_fetch = 0;
      rd_en = 0;
      rs1_en = 0;
      rs2_en = 0;
      rd_din_sel = rd_din_sel_imm;
      alu_din1_sel = alu_din1_sel_rs1;
      alu_din2_sel = alu_din2_sel_imm;
      pc_next_sel = pc_next_sel_stall;
      alu_op = alu_op_nop;
      alu_shift_din2 = 0;
      load_data = 0;
      take_branch = 0;
      store_data = 0;
      case (state)
          state_fetch: begin
              inst_fetch = state_change;
          end
          state_decode: begin
              case (inst_type)
                  inst_type_imm: begin
                      rd_en = 1;
                      rd_din_sel = rd_din_sel_imm;
                      pc_next_sel = pc_next_sel_incr;
                  end
                  inst_type_int_imm: begin
                      rs1_en = 1;
                  end
                  inst_type_int_reg: begin
                      rs1_en = 1;
                      rs2_en = 1;
                  end
                  inst_type_branch: begin
                      rs1_en = 1;
                      rs2_en = 1;
                  end
                  inst_type_store: begin
                      rs1_en = 1;
                      rs2_en = 1;
                  end
                  inst_type_load: begin
                      rs1_en = 1;
                  end
                  inst_type_jalr: begin
                      rs1_en = 1;
                  end
                  inst_type_fence: begin
                      pc_next_sel = pc_next_sel_incr;
                  end
              endcase
          end
          state_exec: begin
              case (inst_type)
                  inst_type_int_imm: begin
                      rd_en = 1;
                      rd_din_sel = rd_din_sel_alu;
                      alu_din1_sel = alu_din1_sel_rs1;
                      alu_din2_sel = alu_din2_sel_imm;
                      pc_next_sel = pc_next_sel_incr;
                      alu_op = get_int_alu_op(funct);
                  end
                  inst_type_int_reg: begin
                      rd_en = 1;
                      rd_din_sel = rd_din_sel_alu;
                      alu_din1_sel = alu_din1_sel_rs1;
                      alu_din2_sel = alu_din2_sel_rs2;
                      pc_next_sel = pc_next_sel_incr;
                      alu_op = get_int_alu_op(funct);
                  end
                  inst_type_branch: begin
                      alu_din1_sel = alu_din1_sel_rs1;
                      alu_din2_sel = alu_din2_sel_rs2;
                      case(funct)
                          funct_eq:
                              take_branch =  alu_comp[alu_comp_eq];
                          funct_neq:
                              take_branch = !alu_comp[alu_comp_eq];
                          funct_lt:
                              take_branch =  alu_comp[alu_comp_lt];
                          funct_gte:
                              take_branch = !alu_comp[alu_comp_lt];
                          funct_ltu:
                              take_branch =  alu_comp[alu_comp_ltu];
                          funct_gteu:
                              take_branch = !alu_comp[alu_comp_ltu];
                      endcase
                      if(take_branch)
                          pc_next_sel = pc_next_sel_add_imm;
                      else
                          pc_next_sel = pc_next_sel_incr;
                  end
                  inst_type_store: begin
                      alu_din1_sel = alu_din1_sel_rs1;
                      alu_din2_sel = alu_din2_sel_imm;
                      alu_op = alu_op_add;
                      store_data = state_change;
                  end
                  inst_type_load: begin
                      alu_din1_sel = alu_din1_sel_rs1;
                      alu_din2_sel = alu_din2_sel_imm;
                      alu_op = alu_op_add;
                      load_data = state_change;
                  end
                  inst_type_jal: begin
                      rd_en = 1;
                      rd_din_sel = rd_din_sel_alu;
                      alu_din1_sel = alu_din1_sel_pc;
                      alu_din2_sel = alu_din2_sel_const_4;
                      pc_next_sel = pc_next_sel_add_imm;
                      alu_op = alu_op_add;
                  end
                  inst_type_auipc: begin
                      rd_en = 1;
                      rd_din_sel = rd_din_sel_alu;
                      alu_din1_sel = alu_din1_sel_pc;
                      alu_din2_sel = alu_din2_sel_imm;
                      pc_next_sel = pc_next_sel_incr;
                      alu_op = alu_op_add;
                  end
                  inst_type_jalr: begin
                      rd_en = 1;
                      rd_din_sel = rd_din_sel_alu;
                      alu_din1_sel = alu_din1_sel_pc;
                      alu_din2_sel = alu_din2_sel_const_4;
                      pc_next_sel = pc_next_sel_add_rs1_imm;
                      alu_op = alu_op_add;
                  end
              endcase
          end
          state_mem: begin
              alu_op = alu_op_add;
              if(inst_type == inst_type_load) begin
                  rd_en = state_change_next;
                  rd_din_sel = rd_din_sel_mem;
              end
              if(state_change_next)
                  pc_next_sel = pc_next_sel_incr;
          end
      endcase
      if (alu_op == alu_op_sll || alu_op == alu_op_slt || alu_op == alu_op_sltu)
        alu_shift_din2 = 1;
  end
  function alu_op_e get_int_alu_op;
      input funct_e funct_t;
      begin
          case(funct_t)
              funct_add:  get_int_alu_op = alu_op_add;
              funct_sub:  get_int_alu_op = alu_op_sub;
              funct_sll:  get_int_alu_op = alu_op_sll;
              funct_slt:  get_int_alu_op = alu_op_slt;
              funct_sltu: get_int_alu_op = alu_op_sltu;
              funct_xor:  get_int_alu_op = alu_op_xor;
              funct_srl:  get_int_alu_op = alu_op_srl;
              funct_sra:  get_int_alu_op = alu_op_sra;
              funct_or:   get_int_alu_op = alu_op_or;
              funct_and:  get_int_alu_op = alu_op_and;
              default:     get_int_alu_op = alu_op_nop;
          endcase
      end
  endfunction
endmodule
