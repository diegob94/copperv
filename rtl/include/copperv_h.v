`default_nettype none

// datapath
`define DATA_WIDTH         32
`define PC_WIDTH           32
`define BUS_WIDTH          32
`define RD_DIN_SEL_WIDTH   1
`define RD_DIN_SEL_IMM     0
`define PC_NEXT_SEL_WIDTH  1
`define PC_NEXT_SEL_STALL  0
`define PC_NEXT_SEL_INCR   1

// regfile
`define REG_WIDTH          5

// alu
`define FUNCT_ADD          0

// idecoder
`define INST_WIDTH         32
`define OPCODE_WIDTH       7
`define IMM_WIDTH          32
`define FUNCT_WIDTH        4
`define INST_TYPE_WIDTH    2
`define INST_TYPE_IMM      0
`define INST_TYPE_INT_IMM  1
`define INST_TYPE_INT_REG  2
`define INST_TYPE_BRANCH   3

// control_unit
`define STATE_WIDTH        3
`define STATE_RESET        0
`define STATE_IDLE         1
`define STATE_FETCH        2
`define STATE_LOAD         3
`define STATE_EXEC         4
`define STATE_MEM          5
