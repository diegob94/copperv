
package copperv1_pkg;

  import DefaultValue :: *;
  
  typedef enum { Error, Ok } Bus_write_response deriving (Bits);
  typedef UInt#(32) Data_t;
  typedef UInt#(32) Addr_t;
  typedef Bit#(32) Imm_t;
  
  typedef enum {
    ZERO, RA, SP, GP, TP, T[0:2],
    S0_FP, S1, A[0:7], S[2:11], T[3:6]
  } Reg_t deriving (Bits, FShow);

  typedef enum {
    Add,
    Sll,
    Slt,
    Sltu,
    Xor, 
    Srl,
    Or,
    And, 
    Sub = 'h100,
    Sra = 'h105
  } Funct_alu deriving (Bits, FShow);

  typedef enum {
    Eq,
    Neq,
    Lt,
    Gte,
    Ltu,
    Gteu
  } Funct_branch deriving (Bits, FShow);

  typedef enum{
    Mem_byte,
    Mem_hword,
    Mem_word,
    Mem_byteu,
    Mem_hwordu
  } Funct_load deriving (Bits, FShow);

  typedef enum{
    Mem_byte,
    Mem_hword,
    Mem_word
  } Funct_store deriving (Bits, FShow);

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
  
//########################### Instruction decoding ############################
  typedef struct {
    Imm_t imm;
    Reg_t rd;
  } Imm_type deriving (Bits, FShow);

  typedef struct {
    Imm_t imm;
    Reg_t rd;
    Reg_t rs1;
    Funct_alu funct;
  } Int_imm_type deriving (Bits, FShow);

  typedef struct {
    Reg_t rd;
    Reg_t rs1;
    Reg_t rs2;
    Funct_alu funct;
  } Int_reg_type deriving (Bits, FShow);

  typedef struct {
    Imm_t imm;
    Reg_t rs1;
    Reg_t rs2;
    Funct_branch funct;
  } Branch_type deriving (Bits, FShow);

  typedef struct {
    Imm_t imm;
    Reg_t rd;
    Reg_t rs1;
    Funct_load funct;
  } Load_type deriving (Bits, FShow);

  typedef struct {
    Imm_t imm;
    Reg_t rs1;
    Reg_t rs2;
    Funct_store funct;
  } Store_type deriving (Bits, FShow);

  typedef union tagged {
    Imm_type Lui;
    Imm_type Auipc;
    Imm_type Jal;
    Int_imm_type Jalr;
    Int_imm_type Int_imm;
    Load_type Load;
    Int_reg_type Int_reg;
    Branch_type Branch;
    Store_type Store;
    void Nop;
    void Halt;
  } Instruction deriving (FShow);
  
  instance Bits#(Instruction, k);
    function Instruction unpack (Bit#(k) data);
      let inst_t = pack(data);
      let opcode = inst_t[6:0];
      let rd = unpack(inst_t[11:7]);
      let rs1 = unpack(inst_t[19:15]);
      let rs2 = unpack(inst_t[24:20]);
      let funct3 = inst_t[14:12];
      let funct7 = inst_t[31:25];
      let funct = unpack(truncate({funct7, funct3}));
      let u_type = Imm_type {
        imm: unpack({inst_t[31:12], 12'b0}), 
        rd:  rd
      };
      let j_type = Imm_type {
        imm: unpack(extend({inst_t[31], inst_t[19:12], inst_t[20], inst_t[30:25], inst_t[24:21], 1'b0})), 
        rd:  rd
      };
      let i_type = Int_imm_type {
        imm: unpack(extend({inst_t[31:20]})),
        rd: rd,
        rs1: rs1,
        funct: funct
      };
      let l_type = Load_type {
        imm: unpack(extend({inst_t[31:20]})),
        rd: rd,
        rs1: rs1,
        funct: funct
      };
      let r_type = Int_reg_type {
        rd: rd,
        rs1: rs1,
        rs2: rs2,
        funct: funct
      };
      let b_type = Branch_type {
        imm: unpack(extend({inst_t[31], inst_t[7], inst_t[30:25], inst_t[11:8], 1'b0})),
        rs1: rs1,
        rs2: rs2,
        funct: funct
      };
      let s_type = Store_type {
        imm: unpack(extend({inst_t[31:25], inst_t[11:7]})),
        rs1: rs1,
        rs2: rs2,
        funct: funct
      };
      case(opcode) matches
        'h37: return tagged Lui     u_type;
        'h17: return tagged Auipc   u_type;
        'h6F: return tagged Jal     j_type;
        'h67: return tagged Jalr    i_type;
        'h13: return tagged Int_imm i_type;
        'h03: return tagged Load    l_type;
        'h33: return tagged Int_reg r_type;
        'h63: return tagged Branch  b_type;
        'h23: return tagged Store   s_type;
        'h0F: return tagged Nop;
        default: return tagged Halt;
      endcase
    endfunction
    function Bit#(k) pack (Instruction data);
      return 0;
    endfunction
  endinstance

endpackage: copperv1_pkg
