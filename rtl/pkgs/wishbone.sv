package wishbone_pkg;
  interface wishbone_if (
    input clk,
    input rst
  );
  parameter adr_width = 8;
  parameter dat_width = 8;
  parameter stb_width = 8;

  logic [adr_width-1:0] adr,
  logic [dat_width-1:0] datwr,
  logic [dat_width-1:0] datrd,
  logic                 we,
  logic                 stb,
  logic                 ack,
  logic                 cyc,
  logic [stb_width-1:0] sel
  
  modport master (
    output [adr_width-1:0] adr,
    output [dat_width-1:0] datwr,
    input  [dat_width-1:0] datrd,
    output                 we,
    output                 stb,
    input                  ack,
    output                 cyc,
    output [stb_width-1:0] sel
  );

  modport slave (
    input                  clk,
    input                  rst,
    input  [adr_width-1:0] adr,
    input  [dat_width-1:0] datwr,
    output [dat_width-1:0] datrd,
    input                  we,
    input                  stb,
    output                 ack,
    input                  cyc,
    input  [stb_width-1:0] sel
  );
  endinterface : wishbone_if
endpackage : wishbone_pkg
