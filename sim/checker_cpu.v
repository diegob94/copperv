`timescale 1ns/1ps
`include "testbench_h.v"
`include "copperv_h.v"

`define OVL_ASSERT_ON
`define OVL_INIT_MSG
`include "std_ovl_defines.h"

module  checker_cpu #(
    parameter inst_width = 32
) (
    input clk,
    input rst
);
parameter severity_level = `OVL_FATAL;
bus_channel_checker #(
    .severity_level(severity_level),
    .channel_name("i_raddr")
) i_raddr_checker (
    .clock(clk),
    .reset(rst),
    .ready(`CPU_INST.i_raddr_ready),
    .valid(`CPU_INST.i_raddr_valid)
);
bus_channel_checker #(
    .severity_level(severity_level),
    .channel_name("i_rdata")
) i_rdata_checker (
    .clock(clk),
    .reset(rst),
    .ready(`CPU_INST.i_rdata_ready),
    .valid(`CPU_INST.i_rdata_valid)
);
endmodule

module bus_channel_checker(
    input clock,
    input reset,
    input valid,
    input ready,
    output wor [`OVL_FIRE_WIDTH-1:0] fire
);
parameter severity_level = `OVL_ERROR;
parameter channel_name = "UNKNOWN";
parameter msg_prefix = {"BUS: ",channel_name,": "};
wire reset_rose;
edge_detector reset_edge (
    .clock(clock),
    .reset(reset),
    .signal(reset),
    .rose(reset_rose)
);
ovl_next #(
    .severity_level(severity_level),
    .property_type(`OVL_ASSERT),
    .msg({msg_prefix,"valid not deasserted after transaction"}),
    .coverage_level(`OVL_COVER_NONE),
    .clock_edge(`OVL_POSEDGE),
    .reset_polarity(`OVL_ACTIVE_LOW),
    .gating_type(`OVL_GATE_NONE)
) transaction_done (
    .clock(clock),
    .reset(reset),
    .enable(1'b1),
    .start_event(valid && ready), 
    .test_expr(!valid),
    .fire(fire)
);
ovl_implication #(
    .severity_level(severity_level),
    .property_type(`OVL_ASSERT),
    .msg({msg_prefix,"valid not deasserted after reset"}),
    .coverage_level(`OVL_COVER_NONE),
    .clock_edge(`OVL_POSEDGE),
    .reset_polarity(`OVL_ACTIVE_LOW),
    .gating_type(`OVL_GATE_NONE)
) reset_done (
    .clock(clock),
    .reset(reset),
    .enable(1'b1),
    .antecedent_expr(reset_rose), 
    .consequent_expr(!valid),
    .fire(fire)
);
endmodule
