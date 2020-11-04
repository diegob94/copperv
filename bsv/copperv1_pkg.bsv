package copperv1_pkg;

  import DefaultValue :: *;
  
  typedef enum { Error, Ok } Bus_write_response deriving (Bits);
  typedef UInt#(32) Data_t;
  typedef UInt#(32) Addr_t;
  typedef UInt#(32) Imm_t;
  
  typedef enum {
    IMM, INT_IMM, INT_REG,
    LOAD, STORE,
    BRANCH, JAL, JALR,
    AUIPC,
    FENCE
  } Inst_type_t;

  typedef enum {
    ZERO, RA, SP, GP, TP, T0, T1, T2,
    S0_FP, S1, A0, A1, A2, A3, A4, A5,
    A6, A7, S2, S3, S4, S5, S6, S7,
    S8, S9, S10, S11, T3, T4, T5, T6
  } Reg_t;
  
  typedef enum {
    ADD, SUB, AND, XOR, OR,
    EQ, NEQ, LT, GTE, LTU, GTEU,
    MEM_BYTE, MEM_HWORD, MEM_WORD,
    MEM_BYTEU, MEM_HWORDU,
    SLL, SLT, SLTU,
    SRL, SRA,
    JAL
  } Funct_t;

  typedef struct { 
    Data_t data;
  } Bus_r_resp deriving (Bits);
  
  typedef struct { 
    Addr_t addr;
  } Bus_r_req deriving (Bits);
  
  instance DefaultValue #( Bus_r_req );
    defaultValue = Bus_r_req { addr : 0 };
  endinstance
  
  typedef struct { 
    Bus_write_response resp;
  } Bus_w_resp deriving (Bits);

  typedef struct { 
    Addr_t addr;
    Data_t data;
  } Bus_w_req deriving (Bits);

  typedef struct {
    Imm_t imm;
    Inst_type_t inst_type;
    Reg_t rd;
    Reg_t rs1;
    Reg_t rs2;
    Funct_t funct;
  } DInstruction deriving (Bits);

endpackage: copperv1_pkg
