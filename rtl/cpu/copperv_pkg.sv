`timescale 1ns/1ps

package copperv_pkg;

  parameter pc_init              = 0;
  parameter data_width           = 32;
  parameter pc_width             = 32;
  parameter bus_width            = 32;
  parameter bus_resp_width       = 1;
  parameter funct3_width         = 3;
  parameter funct7_width         = 7;
  parameter reg_width            = 5;
  parameter reg_t3               = 28;
  parameter alu_shift_din2_width = 5;
  parameter inst_width           = 32;
  parameter imm_width            = 32;

  typedef logic [inst_width-1:0] inst_td;

  typedef enum {
    rd_din_sel_imm,
    rd_din_sel_alu,
    rd_din_sel_mem
  } rd_din_sel_e;

  typedef enum {
    pc_next_sel_stall,
    pc_next_sel_incr,
    pc_next_sel_add_imm,
    pc_next_sel_add_rs1_imm
  } pc_next_sel_e;
  
  typedef enum {
    alu_din1_sel_rs1,
    alu_din1_sel_pc
  } alu_din1_sel_e;

  typedef enum {
    alu_din2_sel_imm,
    alu_din2_sel_rs2,
    alu_din2_sel_const_4
  } alu_din2_sel_e;

  typedef enum {
    data_write_resp_fail,
    data_write_resp_ok
  } data_write_resp_e;

  typedef enum {
    alu_op_nop,
    alu_op_add,
    alu_op_sub,
    alu_op_and,
    alu_op_sll,
    alu_op_sra,
    alu_op_srl,
    alu_op_xor,
    alu_op_or,
    alu_op_slt,
    alu_op_sltu
  } alu_op_e;

  typedef enum {
    alu_comp_eq,
    alu_comp_lt,
    alu_comp_ltu
  } alu_comp_e;

  typedef enum {
    inst_type_imm,
    inst_type_int_imm,
    inst_type_int_reg,
    inst_type_branch,
    inst_type_store,
    inst_type_jal,
    inst_type_auipc,
    inst_type_jalr,
    inst_type_load,
    inst_type_fence
  } inst_type_e;

  typedef enum {
    funct_add,
    funct_sub,
    funct_and,
    funct_eq,
    funct_neq,
    funct_lt,
    funct_gte,
    funct_ltu,
    funct_gteu,
    funct_mem_byte,
    funct_mem_hword,
    funct_mem_word,
    funct_mem_byteu,
    funct_mem_hwordu,
    funct_jal,
    funct_sll,
    funct_slt,
    funct_sltu,
    funct_xor,
    funct_srl,
    funct_sra,
    funct_or
  } funct_e;

  typedef enum {
    opcode_load    = {5'h00, 2'b11},
    opcode_fence   = {5'h03, 2'b11},
    opcode_int_imm = {5'h04, 2'b11},
    opcode_auipc   = {5'h05, 2'b11},
    opcode_store   = {5'h08, 2'b11},
    opcode_int_reg = {5'h0c, 2'b11},
    opcode_lui     = {5'h0d, 2'b11},
    opcode_branch  = {5'h18, 2'b11},
    opcode_jalr    = {5'h19, 2'b11},
    opcode_jal     = {5'h1b, 2'b11}
  } opcode_e;

  // control_unit
  typedef enum {
    state_reset,
    state_idle,
    state_fetch,
    state_decode,
    state_exec,
    state_mem
  } state_e;

endpackage : copperv_pkg
