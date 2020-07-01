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
`define PC_NEXT_SEL_BRANCH   2
`define ALU_DIN1_SEL_WIDTH   1
`define ALU_DIN1_SEL_RS1     1
`define ALU_DIN2_SEL_WIDTH   2
`define ALU_DIN2_SEL_IMM     1
`define ALU_DIN2_SEL_RS2     2
`define DATA_WRITE_RESP_FAIL 0
`define DATA_WRITE_RESP_OK   1

// regfile
`define REG_WIDTH          5

// alu
`define ALU_OP_WIDTH       4
`define ALU_OP_NOP         0
`define ALU_OP_ADD         1
`define ALU_OP_SUB         2
`define ALU_OP_EQ          3
`define ALU_OP_NEQ         4

// idecoder
`define INST_WIDTH         32
`define OPCODE_WIDTH       7
`define IMM_WIDTH          32
`define INST_TYPE_WIDTH    3
`define INST_TYPE_IMM      0
`define INST_TYPE_INT_IMM  1
`define INST_TYPE_INT_REG  2
`define INST_TYPE_BRANCH   3
`define INST_TYPE_STORE    4
`define INST_TYPE_DECODE   5
`define FUNCT_WIDTH        4
`define FUNCT_ADD          0
`define FUNCT_SUB          1
`define FUNCT_EQ           2
`define FUNCT_NEQ          3
`define FUNCT_MEM_BYTE     4
`define FUNCT_MEM_HWORD    5
`define FUNCT_MEM_WORD     6

// control_unit
`define STATE_WIDTH        3
`define STATE_RESET        0
`define STATE_IDLE         1
`define STATE_FETCH        2
`define STATE_DECODE       3
`define STATE_EXEC         4
`define STATE_MEM          5
