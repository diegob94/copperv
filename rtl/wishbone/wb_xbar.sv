`default_nettype none

module wb_xbar #(
    parameter m_count = 2,
    parameter s_count = 2
) (
    input clock,
    input reset,
    wishbone_bus_if.s_modport m_arr [m_count-1:0],
    wishbone_bus_if.m_modport s_arr [s_count-1:0]
);
parameter adr_width = m_arr[0].adr_width;
parameter dat_width = m_arr[0].dat_width;
parameter sel_width = m_arr[0].sel_width;
parameter [adr_width-1:0] adr_map [s_count-1:0] = 0;

wire [adr_width-1:0] logic_adr_map [s_count-1:0];
assign logic_adr_map = adr_map;

typedef struct {
    logic [adr_width-1:0] adr;
    logic [dat_width-1:0] datrd;
    logic [dat_width-1:0] datwr;
    logic [sel_width-1:0] sel;
    logic ack;
    logic we;
} wb_transaction_t;

typedef struct {
    wb_transaction_t wb;
    logic flag;
} buf_t;

buf_t buf_arr [m_count-1:0];
logic [m_count-1:0] dst_to_src_map [s_count-1:0];
logic [s_count-1:0] adr_less_than_map [m_count-1:0];
logic [s_count-1:0] adr_greater_than_map [m_count-1:0];
logic [$clog2(m_count+1)-1:0] buf_index [s_count-1];
genvar i;
genvar j;
generate
    for(i = 0; i < m_count; i++) begin
        always_comb
            m_arr[i].ack = 0;
        always_ff @(posedge clock) begin : buffer_register
            if(reset)
                buf_arr[i].flag <= 0;
            else if(m_arr[i].cyc && m_arr[i].stb) begin
                buf_arr[i].flag <= 1;
                buf_arr[i].wb.we <= m_arr[i].we;
                buf_arr[i].wb.adr <= m_arr[i].adr;
                if(m_arr[i].we) begin
                    buf_arr[i].wb.datwr <= m_arr[i].datwr;
                    buf_arr[i].wb.sel <= m_arr[i].sel;
                end
            end
        end : buffer_register
    end
    for(i = 0; i < m_count; i++) begin
        for(j = 0; j < s_count; j++) begin
            always_comb begin
                dst_to_src_map[j][i] = 0;
                adr_greater_than_map[i][j] = 0;
                adr_less_than_map[i][j] = 0;
                if(buf_arr[i].flag) begin
                    adr_greater_than_map[i][j] = buf_arr[i].wb.adr >= logic_adr_map[j];
                    adr_less_than_map[i][j] = 1;
                    if (j < s_count - 1)
                        adr_less_than_map[i][j] = buf_arr[i].wb.adr < logic_adr_map[j + 1];
                    if(adr_greater_than_map[i][j] && adr_less_than_map[i][j]) begin
                        dst_to_src_map[j][i] = 1;
                    end
                end
            end
        end
    end
    for(j = 0; j < s_count; j++) begin
        always_comb begin
            s_arr[j].cyc = 0;
            s_arr[j].stb = 0;
            s_arr[j].we = 0;
            s_arr[j].adr = 0;
            s_arr[j].datwr = 0;
            s_arr[j].sel = 0;
            buf_index[j] = 0;
            if(|(dst_to_src_map[j])) begin
                for(int k = 0; k < m_count; k++) begin
                    if(dst_to_src_map[j][k])
                        buf_index[j] = k;
                end
                if(buf_arr[buf_index[j]].flag) begin
                    s_arr[j].cyc = 1;
                    s_arr[j].stb = 1;
                    s_arr[j].adr = buf_arr[buf_index[j]].wb.adr;
                    if(buf_arr[buf_index[j]].wb.we) begin
                        s_arr[j].we = 1;
                        s_arr[j].datwr = buf_arr[buf_index[j]].wb.datwr;
                        s_arr[j].sel = buf_arr[buf_index[j]].wb.sel;
                    end
                end
            end
        end
    end
endgenerate
endmodule : wb_xbar

module test_wb_xbar();
wire clock;
wire reset;
parameter s_count = 2;
parameter m_count = 2;
parameter dat_width = 32;
parameter adr_width = 32;
parameter adr_map_1 = 0;
parameter adr_map_2 = 32'h8000_0000;
wishbone_bus_if #(.dat_width(dat_width),.adr_width(adr_width)) m_arr [s_count-1:0] ();
wishbone_bus_if #(.dat_width(dat_width),.adr_width(adr_width)) s_arr [m_count-1:0] ();
wb_xbar #(.m_count(m_count),.s_count(s_count),.adr_map('{adr_map_1,adr_map_2})) xbar (.*);
`ifdef FORMAL
`include "formal/wb_xbar.v"
`endif
endmodule : test_wb_xbar

