package copperv_pkg;

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

  typedef enum {
    add,
    sub,
    and,
    eq,
    neq,
    lt,
    gte,
    ltu,
    gteu,
    mem_byte,
    mem_hword,
    mem_word,
    mem_byteu,
    mem_hwordu,
    jal,
    sll,
    slt,
    sltu,
    xor,
    srl,
    sra,
    or
  } funct_e;

  typedef enum {
    load    = {5'h00, 2'b11},
    fence   = {5'h03, 2'b11},
    int_imm = {5'h04, 2'b11},
    auipc   = {5'h05, 2'b11},
    store   = {5'h08, 2'b11},
    int_reg = {5'h0c, 2'b11},
    lui     = {5'h0d, 2'b11},
    branch  = {5'h18, 2'b11},
    jalr    = {5'h19, 2'b11},
    jal     = {5'h1b, 2'b11}
  } opcode_e;

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
