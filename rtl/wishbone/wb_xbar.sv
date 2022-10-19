// sv2v -DFORMAL=1 -I. rtl/wishbone/wb_xbar.sv

`default_nettype none

interface WishboneBus #(
        parameter addr_width = 8,
        parameter data_width = 8,
        parameter strobe_width = addr_width/8,
        parameter resp_width = 1
    );
    logic [addr_width-1:0]   adr;
    logic [data_width-1:0]   datwr;
    logic [data_width-1:0]   datrd;
    logic                    we;
    logic                    stb;
    logic                    ack;
    logic                    cyc;
    logic [strobe_width-1:0] sel;
    modport Master (
        output adr,
        output datwr,
        input  datrd,
        output we,
        output stb,
        input  ack,
        output cyc,
        output sel
    );
    modport Slave (
        input  adr,
        input  datwr,
        output datrd,
        input  we,
        input  stb,
        output ack,
        input  cyc,
        input  sel
    );
endinterface

module wb_xbar #(
    parameter master_count = 2,
    parameter slave_count = 2
) (
        input clock,
        input reset,
        WishboneBus.Slave masters [master_count-1:0],
        WishboneBus.Master slaves [slave_count-1:0]
    );
    always_ff @(posedge clock) begin
        masters[0].datrd <= ~masters[0].datwr;
        masters[1].datrd <= masters[1].datwr;
    end
endmodule

module test_wb_xbar(
    input clock,
    input reset
//    inout [1000:0] buses,
);
    `ifdef FORMAL
    `include "formal/uart_tx.v"
    `endif
    WishboneBus #(.data_width(32)) masters [2-1:0] ();
    WishboneBus #(.data_width(32)) slaves [2-1:0] ();
    wb_xbar xbar(.*);
//    assign buses = {
//        masters[0].adr, masters[0].datwr, masters[0].datrd, masters[0].we, 
//        masters[0].stb, masters[0].ack, masters[0].cyc, masters[0].sel,
//        masters[1].adr, masters[1].datwr, masters[1].datrd, masters[1].we, 
//        masters[1].stb, masters[1].ack, masters[1].cyc, masters[1].sel,
//        slaves[0].adr, slaves[0].datwr, slaves[0].datrd, slaves[0].we, 
//        slaves[0].stb, slaves[0].ack, slaves[0].cyc, slaves[0].sel,
//        slaves[1].adr, slaves[1].datwr, slaves[1].datrd, slaves[1].we, 
//        slaves[1].stb, slaves[1].ack, slaves[1].cyc, slaves[1].sel
//    };
endmodule

