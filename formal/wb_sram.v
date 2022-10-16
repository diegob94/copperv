`define FORMAL_WB_S 1
`include "formal/wb.v"

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


