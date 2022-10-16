`ifdef FORMAL_WB_S
    `define ASSERT_WB_M assume
    `define ASSERT_WB_S assert
`endif
`ifdef FORMAL_WB_M
    `define ASSERT_WB_M assert
    `define ASSERT_WB_S assume
`endif

always @(posedge clock) begin
    // RULE 3.20
    if(f_past_valid && $fell(reset)) begin
        `ASSERT_WB_M(!wb_stb && !wb_cyc);
        `ASSERT_WB_S(!wb_ack); // is this stated in spec?
    end
    if(reset)
        `ASSERT_WB_M(!wb_stb && !wb_cyc);
    // RULE 3.25
    if(!wb_cyc)
        `ASSERT_WB_M(!wb_stb);
    // RULE 3.50
    if(!reset && !wb_stb)
        `ASSERT_WB_S(!wb_ack);
    // OBSERVATION 3.10
    if(f_past_valid && !reset && $fell(wb_stb))
        `ASSERT_WB_S($fell(wb_ack));
    // RULE 3.60
    if(f_past_valid && $past(wb_stb)) begin
        `ASSERT_WB_M($stable(wb_sel));
        `ASSERT_WB_M($stable(wb_adr));
        `ASSERT_WB_M($stable(wb_datwr));
        `ASSERT_WB_M($stable(wb_we));
    end
    // RULE 3.65
    if(f_past_valid && $past(wb_ack)) begin
        `ASSERT_WB_S($stable(wb_datrd));
    end
    // Handshaking Protocol
    if(f_past_valid && $past(wb_stb) && !$past(wb_ack))
        `ASSERT_WB_M(wb_stb);
    if(f_past_valid && $past(wb_stb) && $past(wb_ack))
        `ASSERT_WB_M(!wb_stb);
    // Basic covers
    if(!reset) begin
        cover(wb_ack);
        cover(wb_cyc && !wb_stb);
        cover(wb_stb && !wb_we);
        cover(wb_stb && wb_we);
    end
end

