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
//reg a = 1;
//ovl_always #(
//    .severity_level(severity_level),
//    .property_type(`OVL_ASSERT),
//    .msg("ERRORORORORORORORO"),
//    .coverage_level(`OVL_COVER_NONE),
//    .clock_edge(`OVL_POSEDGE),
//    .reset_polarity(`OVL_ACTIVE_LOW),
//    .gating_type(`OVL_GATE_NONE)
//) test_assertion (
//    .clock(clk),
//    .reset(rst),
//    .enable(1'b1),
//    .test_expr(~a),
//    .fire()
//);
endmodule
