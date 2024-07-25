package wishbone_pkg;
  interface wishbone;
    parameter addr_width = 8;
    parameter data_width = 8;
    parameter strobe_width = 8;

    logic                    clock,
    logic                    reset,
    logic [addr_width-1:0]   wb_adr,
    logic [data_width-1:0]   wb_datwr,
    logic [data_width-1:0]   wb_datrd,
    logic                    wb_we,
    logic                    wb_stb,
    logic                    wb_ack,
    logic                    wb_cyc,
    logic [strobe_width-1:0] wb_sel
    
    modport master (
      input                      clock,
      input                      reset,
      output  [addr_width-1:0]   wb_adr,
      output  [data_width-1:0]   wb_datwr,
      input [data_width-1:0]     wb_datrd,
      output                     wb_we,
      output                     wb_stb,
      input                      wb_ack,
      output                     wb_cyc,
      output  [strobe_width-1:0] wb_sel
    );

    modport slave (
      input                     clock,
      input                     reset,
      input  [addr_width-1:0]   wb_adr,
      input  [data_width-1:0]   wb_datwr,
      output [data_width-1:0]   wb_datrd,
      input                     wb_we,
      input                     wb_stb,
      output                    wb_ack,
      input                     wb_cyc,
      input  [strobe_width-1:0] wb_sel
    );
  endinterface : wishbone
endpackage : wishbone_pkg
