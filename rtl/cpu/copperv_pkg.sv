package copperv_pkg;
// datapath
parameter data_width              = 32;
parameter pc_width                = 32;
parameter bus_width               = 32;
parameter bus_resp_width          = 1;

  typedef enum {
    imm,
    alu,
    mem
  } rd_din_sel_e;

  typedef enum {
    stall,
    incr,
    add_imm,
    add_rs1_imm
  } pc_next_sel_e;
  
  typedef enum {
    rs1,
    pc
  } alu_din1_sel_e;

  typedef enum {
    imm,
    rs2,
    const_4
  } alu_din2_sel_e;

  typedef enum {
    fail,
    ok
  } data_write_resp_e;

// regfile
parameter reg_width         = 5;
parameter reg_t3            = 28;

// alu
parameter alu_shift_din2_width = 5;

  typedef enum {
    nop,
    add,
    sub,
    and,
    sll,
    sra,
    srl,
    xor,
    or,
    slt,
    sltu
  } alu_op_e;

  typedef enum {
    eq,
    lt,
    ltu
  } alu_comp_e;

// idecoder
parameter inst_width        = 32;
parameter imm_width         = 32;

  typedef enum {
    imm,
    int_imm,
    int_reg,
    branch,
    store,
    jal,
    auipc,
    jalr,
    load,
    fence
  } inst_type_e;

parameter funct_width       = 5;
parameter funct_add         = 0;
parameter funct_sub         = 1;
parameter funct_and         = 2;
parameter funct_eq          = 3;
parameter funct_neq         = 4;
parameter funct_lt          = 5;
parameter funct_gte         = 6;
parameter funct_ltu         = 7;
parameter funct_gteu        = 8;
parameter funct_mem_byte    = 9;
parameter funct_mem_hword   = 10;
parameter funct_mem_word    = 11;
parameter funct_mem_byteu   = 12;
parameter funct_mem_hwordu  = 13;
parameter funct_jal         = 14;
parameter funct_sll         = 15;
parameter funct_slt         = 16;
parameter funct_sltu        = 17;
parameter funct_xor         = 18;
parameter funct_srl         = 19;
parameter funct_sra         = 20;
parameter funct_or          = 21;

parameter opcode_width      = 7;
parameter opcode_load       = {5'h00, 2'b11};
parameter opcode_fence      = {5'h03, 2'b11};
parameter opcode_int_imm    = {5'h04, 2'b11};
parameter opcode_auipc      = {5'h05, 2'b11};
parameter opcode_store      = {5'h08, 2'b11};
parameter opcode_int_reg    = {5'h0c, 2'b11};
parameter opcode_lui        = {5'h0d, 2'b11};
parameter opcode_branch     = {5'h18, 2'b11};
parameter opcode_jalr       = {5'h19, 2'b11};
parameter opcode_jal        = {5'h1b, 2'b11};

parameter funct3_width      = 3;
parameter funct7_width      = 7;

  // control_unit
  typedef enum {
    reset,
    idle,
    fetch,
    decode,
    exec,
    mem
  } state_e;
endpackage : copperv_pkg
