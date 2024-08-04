interface wishbone_if;
  parameter adr_width = 8;
  parameter dat_width = 8;
  parameter stb_width = 8;

  logic [adr_width-1:0] adr;
  logic [dat_width-1:0] datwr;
  logic [dat_width-1:0] datrd;
  logic                 we;
  logic                 stb;
  logic                 ack;
  logic                 cyc;
  logic [stb_width-1:0] sel;
  
  modport master (
    output adr,
    output datwr,
    input  datrd,
    output we,
    output stb,
    input  ack,
    output cyc,
    output sel
  );

  modport slave (
    input  adr,
    input  datwr,
    output datrd,
    input  we,
    input  stb,
    output ack,
    input  cyc,
    input  sel
  );
endinterface : wishbone_if
