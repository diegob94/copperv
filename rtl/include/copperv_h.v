`default_nettype none

// datapath
`define DATA_WIDTH           32
`define PC_WIDTH             32
`define BUS_WIDTH            32
`define BUS_RESP_WIDTH       1
`define RD_DIN_SEL_WIDTH     1
`define RD_DIN_SEL_IMM       0
`define RD_DIN_SEL_ALU       1
`define PC_NEXT_SEL_WIDTH    2
`define PC_NEXT_SEL_STALL    0
`define PC_NEXT_SEL_INCR     1
`define PC_NEXT_SEL_ADD_IMM  2
`define ALU_DIN1_SEL_WIDTH   2
`define ALU_DIN1_SEL_RS1     1
`define ALU_DIN1_SEL_PC      2
`define ALU_DIN2_SEL_WIDTH   2
`define ALU_DIN2_SEL_IMM     1
`define ALU_DIN2_SEL_RS2     2
`define ALU_DIN2_SEL_CONST_4 3
`define DATA_WRITE_RESP_FAIL 0
`define DATA_WRITE_RESP_OK   1

// regfile
`define REG_WIDTH          5

// alu
`define ALU_OP_WIDTH       4
`define ALU_OP_NOP         0
`define ALU_OP_ADD         1
`define ALU_OP_SUB         2
`define ALU_OP_AND         3
`define ALU_COMP_WIDTH     3
`define ALU_COMP_EQ        0
`define ALU_COMP_LT        1
`define ALU_COMP_LTU       2

// idecoder
`define INST_WIDTH         32
`define OPCODE_WIDTH       7
`define IMM_WIDTH          32
`define INST_TYPE_WIDTH    4
`define INST_TYPE_IMM      0
`define INST_TYPE_INT_IMM  1
`define INST_TYPE_INT_REG  2
`define INST_TYPE_BRANCH   3
`define INST_TYPE_STORE    4
`define INST_TYPE_JAL      5
`define INST_TYPE_AUIPC    6
`define FUNCT_WIDTH        4
`define FUNCT_ADD          0
`define FUNCT_SUB          1
`define FUNCT_AND          2
`define FUNCT_EQ           3
`define FUNCT_NEQ          4
`define FUNCT_LT           5
`define FUNCT_GTE          6
`define FUNCT_LTU          7
`define FUNCT_GTEU         8
`define FUNCT_MEM_BYTE     9
`define FUNCT_MEM_HWORD    10
`define FUNCT_MEM_WORD     11
`define FUNCT_JAL          12
`define OPCODE_LUI         {6'h0D, 2'b11}
`define OPCODE_JAL         {6'h1B, 2'b11}
`define OPCODE_AUIPC       {6'h05, 2'b11}

// control_unit
`define STATE_WIDTH        3
`define STATE_RESET        0
`define STATE_IDLE         1
`define STATE_FETCH        2
`define STATE_DECODE       3
`define STATE_EXEC         4
`define STATE_MEM          5
