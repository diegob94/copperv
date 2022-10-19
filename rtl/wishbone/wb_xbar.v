
module wb_xbar #(
    parameter adr_width = 32,
    parameter dat_width = 32,
    parameter sel_width = adr_width/8,
    parameter master_count = 2,
    parameter slave_count = 2
)(
    input  clock,
    input  reset,
    input  [(master_count*adr_width)-1:0] wb_m_adr,
    input  [(master_count*dat_width)-1:0] wb_m_datwr,
    output [(master_count*dat_width)-1:0] wb_m_datrd,
    input  [master_count-1:0]             wb_m_we,
    input  [master_count-1:0]             wb_m_stb,
    output [master_count-1:0]             wb_m_ack,
    input  [master_count-1:0]             wb_m_cyc,
    input  [(master_count*sel_width)-1:0] wb_m_sel,
    output [(slave_count*adr_width)-1:0]  wb_s_adr,
    output [(slave_count*dat_width)-1:0]  wb_s_datwr,
    input  [(slave_count*dat_width)-1:0]  wb_s_datrd,
    output [slave_count-1:0]              wb_s_we,
    output [slave_count-1:0]              wb_s_stb,
    input  [slave_count-1:0]              wb_s_ack,
    output [slave_count-1:0]              wb_s_cyc,
    output [(slave_count*sel_width)-1:0]  wb_s_sel
);

    genvar i;
    generate
        for (i = 0; i < slave_count; i = i + 1) begin : slaves
            wire [(adr_width-1):0] adr = wb_s_adr[i+:adr_width];
            wire [(dat_width-1):0] datwr = wb_s_datwr[i+:dat_width];
            wire [(dat_width-1):0] datrd = wb_s_datrd[i+:dat_width];
            wire we = wb_s_we[i];
            wire stb = wb_s_stb[i];
            wire ack = wb_s_ack[i];
            wire cyc = wb_s_cyc[i];
            wire [sel_width-1:0] sel = wb_s_sel[i+:strobe_width];
        end
        for (i = 0; i < slave_count; i = i + 1) begin : masters
            wire [(adr_width-1):0] adr = wb_m_adr[i+:adr_width];
            wire [(dat_width-1):0] datwr = wb_m_datwr[i+:dat_width];
            wire [(dat_width-1):0] datrd = wb_m_datrd[i+:dat_width];
            wire we = wb_m_we[i];
            wire stb = wb_m_stb[i];
            wire ack = wb_m_ack[i];
            wire cyc = wb_m_cyc[i];
            wire [sel_width-1:0] sel = wb_m_sel[i+:strobe_width];
        end
    endgenerate

endmodule
