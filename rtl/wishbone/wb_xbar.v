
module wb_xbar #(
    parameter adr_width = 32,
    parameter dat_width = 32,
    parameter sel_width = adr_width/8,
    parameter m_count = 2,
    parameter s_count = 2
)(
    input  clock,
    input  reset,

    input  [(m_count*adr_width)-1:0] wb_m_adr,
    output [(m_count*dat_width)-1:0] wb_m_datrd,
    input  [(m_count*dat_width)-1:0] wb_m_datwr,
    input  [(m_count*sel_width)-1:0] wb_m_sel,
    input  [m_count-1:0]             wb_m_we,
    input  [m_count-1:0]             wb_m_stb,
    input  [m_count-1:0]             wb_m_cyc,
    output [m_count-1:0]             wb_m_ack,

    output [(s_count*adr_width)-1:0]  wb_s_adr,
    input  [(s_count*dat_width)-1:0]  wb_s_datrd,
    output [(s_count*dat_width)-1:0]  wb_s_datwr,
    output [(s_count*sel_width)-1:0]  wb_s_sel,
    output [s_count-1:0]              wb_s_we,
    output [s_count-1:0]              wb_s_stb,
    output [s_count-1:0]              wb_s_cyc,
    input  [s_count-1:0]              wb_s_ack
);

    `ifdef FORMAL
        `include "formal/wb_xbar.v"
    `endif

    genvar i;
    generate
        for (i = 0; i < s_count; i = i + 1) begin : s_arr
            wire [adr_width-1:0] adr;
            wire [dat_width-1:0] datrd;
            wire [dat_width-1:0] datwr;
            wire [sel_width-1:0] sel;
            wire we;
            wire stb;
            wire cyc;
            wire ack;
            assign wb_s_adr[(i*adr_width)+:adr_width] = adr;
            assign datrd = wb_s_datrd[(i*dat_width)+:dat_width];
            assign wb_s_datwr[(i*dat_width)+:dat_width] = datwr;
            assign wb_s_sel[(i*dat_width)+:strobe_width] = sel;
            assign wb_s_we[i] = we;
            assign wb_s_stb[i] = stb;
            assign wb_s_cyc[i] = cyc;
            assign ack = wb_s_ack[i];
        end
        for (i = 0; i < m_count; i = i + 1) begin : m_arr
            wire [(adr_width-1):0] adr;
            wire [(dat_width-1):0] datrd;
            wire [(dat_width-1):0] datwr;
            wire [sel_width-1:0] sel;
            wire we;
            wire stb;
            wire cyc;
            wire ack;
            assign adr = wb_m_adr[(i*adr_width)+:adr_width];
            assign wb_m_datrd[(i*dat_width)+:dat_width] = datrd;
            assign datwr = wb_m_datwr[(i*dat_width)+:dat_width];
            assign sel = wb_m_sel[(i*dat_width)+:strobe_width];
            assign we = wb_m_we[i];
            assign stb = wb_m_stb[i];
            assign cyc = wb_m_cyc[i];
            assign wb_m_ack[i] = ack;
        end
    endgenerate

    generate
        for (i = 0; i < s_count; i = i + 1) begin
            assign s_arr[i].adr = m_arr[0].adr;
        end
    endgenerate

endmodule
