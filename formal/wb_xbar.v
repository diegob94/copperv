
genvar i;
generate
    for (i = 0; i < s_count; i = i + 1) begin
        formal_wb_s #(
            .adr_width(s_arr[i].adr_width),
            .dat_width(s_arr[i].dat_width),
            .sel_width(s_arr[i].sel_width)
        ) u_formal_wb_s (
            .clock(clock),
            .reset(reset),
            .wb_adr(s_arr[i].adr),
            .wb_datrd(s_arr[i].datrd),
            .wb_datwr(s_arr[i].datwr),
            .wb_sel(s_arr[i].sel),
            .wb_we(s_arr[i].we),
            .wb_stb(s_arr[i].stb),
            .wb_cyc(s_arr[i].cyc),
            .wb_ack(s_arr[i].ack)
        );
    end
    for (i = 0; i < m_count; i = i + 1) begin
        formal_wb_m #(
            .adr_width(m_arr[i].adr_width),
            .dat_width(m_arr[i].dat_width),
            .sel_width(m_arr[i].sel_width)
        ) u_formal_wb_m (
            .clock(clock),
            .reset(reset),
            .wb_adr(m_arr[i].adr),
            .wb_datrd(m_arr[i].datrd),
            .wb_datwr(m_arr[i].datwr),
            .wb_sel(m_arr[i].sel),
            .wb_we(m_arr[i].we),
            .wb_stb(m_arr[i].stb),
            .wb_cyc(m_arr[i].cyc),
            .wb_ack(m_arr[i].ack)
        );
    end
endgenerate

//reg f_past_valid = 0;
//initial begin 
//    assume(reset == 1);
//end
//always @(posedge clock) begin
//    f_past_valid <= 1;
//end

