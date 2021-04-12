reg f_past_valid = 0;
reg f_past2_valid = 0;
always @(posedge clock) begin
    if(!reset)
        assert(baud_count < clock_per_bit);
    if(clock_per_bit > 1)
        if(f_past2_valid && !$past(reset,2) && !$past(reset) && !$past(data_load) && $past(tx) != $past(tx,2))
            assert($stable(tx));
    if(f_past_valid && $past(data_load) && !$past(reset) && $past(tx)) begin
        assert($fell(tx));
    end
    if(!reset) begin
        cover(tx_done == 1);
        `ifdef COVER_BASIC_TX
        if(data_load)
            assume(data != 0);
        `endif
    end
    if(f_past_valid && $past(reset)) begin
        assert(!tx_done);
        assert(tx);
    end
end
initial begin 
    assume(reset == 1);
    assume(clock_per_bit > 0);
    `ifdef COVER_BASIC_TX
    assume(clock_per_bit == 2);
    `endif
end
always @(posedge clock) begin
    f_past_valid <= 1;
    f_past2_valid <= f_past_valid;
end
always @(posedge clock) begin
    if($past(reset) && !reset)
        assert(state == IDLE);
    assume(clock_per_bit > 0);
    if(f_past_valid)
        assume(clock_per_bit == $past(clock_per_bit));
end
