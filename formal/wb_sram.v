
fwb_slave #(
    .AW(addr_width),
    .DW(data_width),
) u_fwb_s (
    .i_clk(clock),
    .i_reset(reset),
    .i_wb_cyc(wb_cyc),
    .i_wb_stb(wb_stb),
    .i_wb_we(wb_we),
    .i_wb_addr(wb_adr),
    .i_wb_data(wb_datwr),
    .i_wb_sel(wb_sel),
    .i_wb_ack(wb_ack),
    .i_wb_stall(0),
    .i_wb_idata(wb_datrd),
    .i_wb_err(0)
);

initial wb_ack = 0;

reg f_past_valid = 0;
initial begin 
    assume(reset == 1);
end
always @(posedge clock) begin
    f_past_valid <= 1;
end

`ifdef COVER_WB_SRAM
    (* anyconst *) wire [31:0] f_const_data;
    (* anyconst *) wire [31:0] f_const_addr;
    initial begin
        assume(wb_datrd != f_const_data);
        assume(f_const_data != 0);
        assume(wb_adr == f_const_addr);
    end
    always @(posedge clock) begin
        cover(wb_ack && wb_datrd == f_const_data);
        if(f_past_valid)
            assume(wb_adr == $past(wb_adr));
    end
`endif


