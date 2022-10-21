`default_nettype none

interface wishbone_bus_if #(
        parameter adr_width = 8,
        parameter dat_width = 8,
        parameter sel_width = adr_width/8,
    );
    logic [adr_width-1:0] adr;
    logic [dat_width-1:0] datrd;
    logic [dat_width-1:0] datwr;
    logic [sel_width-1:0] sel;
    logic                 we;
    logic                 stb;
    logic                 cyc;
    logic                 ack;
    logic                 rty;
    modport m_modport (
        output adr, datwr, sel, we, stb, cyc,
        input  datrd, ack, rty
    );
    modport s_modport (
        input  adr, datwr, sel, we, stb, cyc,
        output datrd, ack, rty
    );
endinterface

module wb_xbar #(
    parameter m_count = 2,
    parameter s_count = 2
) (
        input clock,
        input reset,
        wishbone_bus_if.s_modport m_arr [m_count-1:0],
        wishbone_bus_if.m_modport s_arr [s_count-1:0]
    );
    always_ff @(posedge clock) begin
        m_arr[0].datrd <= ~m_arr[0].datwr;
        m_arr[1].datrd <= m_arr[1].datwr;
    end
endmodule

module test_wb_xbar();
    wire clock;
    wire reset;
    parameter s_count = 2;
    parameter m_count = 2;
    wishbone_bus_if #(.dat_width(32)) m_arr [s_count-1:0] ();
    wishbone_bus_if #(.dat_width(32)) s_arr [m_count-1:0] ();
    wb_xbar #(.m_count(m_count),.s_count(s_count)) xbar (.*);
    `ifdef FORMAL
    `include "formal/wb_xbar.v"
    `endif
endmodule

