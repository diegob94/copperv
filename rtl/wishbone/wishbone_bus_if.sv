
interface wishbone_bus_if #(
    parameter adr_width = 8,
    parameter dat_width = 8,
    parameter sel_width = adr_width/8,
);
logic [adr_width-1:0] adr;
logic [dat_width-1:0] datrd;
logic [dat_width-1:0] datwr;
logic [sel_width-1:0] sel;
logic we;
logic stb;
logic cyc;
logic ack;
modport m_modport (
    output adr, datwr, sel, we, stb, cyc,
    input  datrd, ack
);
modport s_modport (
    input  adr, datwr, sel, we, stb, cyc,
    output datrd, ack
);
endinterface : wishbone_bus_if

