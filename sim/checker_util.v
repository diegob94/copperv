`timescale 1ns/1ps
`include "testbench_h.v"

module edge_detector(
    input clock,
    input reset,
    input signal,
    output fell,
    output rose,
    output changed
);
wire signal_past;
past u_signal_past(
    .clock(clock),
    .reset(reset),
    .signal(signal),
    .signal_past(signal_past)
);
assign fell = signal_past && !signal;
assign rose = !signal_past && signal;
assign changed = signal_past != signal;
endmodule

module past #(
    parameter width = 1
)(
    input clock,
    input reset,
    input [width-1:0] signal,
    output [width-1:0] signal_past
);
reg [width-1:0] signal_past;
always @(posedge clock)
    if(!reset)
        signal_past <= 0;
    else
        signal_past <= signal;
endmodule

module flag #(
    parameter async_up = `FALSE,
    parameter async_down = `FALSE
)(
    input clock,
    input reset,
    input up,
    input down,
    output reg flag
);
reg flag_reg;
always @(*) begin
    flag = flag_reg;
    if(async_up == `TRUE)
        flag = flag || up;
    if(async_down == `TRUE)
        flag = flag && !down;
end
always @(posedge clock)
    if(!reset)
        flag_reg <= 0;
    else if(up)
        flag_reg <= 1;
    else if(down)
        flag_reg <= 0;
endmodule

