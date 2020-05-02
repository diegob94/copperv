`default_nettype none

`define BUS_WIDTH          32
`define INST_TYPE_WIDTH    2
`define STATE_WIDTH        2
`define RD_DIN_SEL_WIDTH   1
`define DATA_WIDTH         32
`define RD_DIN_SEL_IMM     0
`define PC_WIDTH           32

// regfile
`define REG_WIDTH          5

// alu
`define FUNCT_ADD          0

// idecoder
`define INST_WIDTH         32
`define OPCODE_WIDTH       7
`define IMM_WIDTH          32
`define FUNCT_WIDTH        4
`define INST_TYPE_IMM      0
`define INST_TYPE_INT_IMM  1
`define INST_TYPE_INT_REG  2
`define INST_TYPE_BRANCH   3

// control_unit
`define FETCH_S            0
`define LOAD_S             1
`define EXEC_S             2
`define MEM_S              3
