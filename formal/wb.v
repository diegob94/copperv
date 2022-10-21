
`ifndef FORMAL_WB_M
module formal_wb_s #(
`else
module formal_wb_m #(
`endif
    parameter adr_width = 32,
    parameter dat_width = 32,
    parameter sel_width = adr_width/8,
) (
    input                 clock,
    input                 reset,
    input [adr_width-1:0] wb_adr,
    input [dat_width-1:0] wb_datrd,
    input [dat_width-1:0] wb_datwr,
    input [sel_width-1:0] wb_sel,
    input                 wb_we,
    input                 wb_stb,
    input                 wb_cyc,
    input                 wb_ack,
);

    reg f_past_valid = 0;
    initial begin 
        assume(reset == 1);
    end
    always @(posedge clock) begin
        f_past_valid <= 1;
    end

    always @(posedge clock) begin
        // RULE 3.20
        if(f_past_valid && $fell(reset)) begin
            assume(!wb_stb && !wb_cyc);
            assert(!wb_ack); // is this stated in spec?
        end
        if(reset)
            assume(!wb_stb && !wb_cyc);
        // RULE 3.25
        if(!wb_cyc)
            assume(!wb_stb);
        // RULE 3.50
        if(!reset && !wb_stb)
            assert(!wb_ack);
        // OBSERVATION 3.10
        if(f_past_valid && !reset && $fell(wb_stb))
            assert($fell(wb_ack));
        // RULE 3.60
        if(f_past_valid && $past(wb_stb)) begin
            assume($stable(wb_sel));
            assume($stable(wb_adr));
            assume($stable(wb_datwr));
            assume($stable(wb_we));
        end
        // RULE 3.65
        if(f_past_valid && $past(wb_ack)) begin
            assert($stable(wb_datrd));
        end
        // Handshaking Protocol
        if(f_past_valid && $past(wb_stb) && !$past(wb_ack))
            assume(wb_stb);
        if(f_past_valid && $past(wb_stb) && $past(wb_ack))
            assume(!wb_stb);
        // Cover
        if(!reset) begin
            cover(wb_ack);
            cover(wb_cyc && !wb_stb);
            cover(wb_stb && !wb_we);
            cover(wb_stb && wb_we);
        end
    end

endmodule

