interface wishbone_if;
  parameter adr_width = 8;
  parameter dat_width = 8;
  parameter sel_width = 8;

  logic [adr_width-1:0] adr;
  logic [dat_width-1:0] datwr;
  logic [dat_width-1:0] datrd;
  logic                 we;
  logic                 stb;
  logic                 ack;
  logic                 cyc;
  logic [sel_width-1:0] sel;
  
  modport master (
    input  datrd, ack,
    output adr, datwr, we, stb, cyc, sel
  );

  modport slave (
    output  datrd, ack,
    input adr, datwr, we, stb, cyc, sel
  );
endinterface : wishbone_if
