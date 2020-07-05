`timescale 1ns/1ps
`include "testbench_h.v"
`include "copperv_h.v"

`define OVL_ASSERT_ON
`define OVL_INIT_MSG
`include "std_ovl_defines.h"

module  checker_cpu #(
    parameter inst_width = 32
) (
    input clock,
    input reset
);
parameter severity_level = `OVL_FATAL;
parameter msg_prefix = {"CHECKER_CPU: "};
wor [`OVL_FIRE_WIDTH-1:0] fire;
wire reset_rose;
wire first_i_raddr_tran;
edges reset_edge (
    .clock(clock),
    .reset(reset),
    .signal(reset),
    .rose(reset_rose)
);
flag #(
    .async_up(`TRUE),
    .async_down(`TRUE)
) u_first_i_addr_tran (
    .clock(clock),
    .reset(reset),
    .up(reset_rose),
    .down(`CPU_INST.ir_addr_valid && `CPU_INST.ir_addr_ready),
    .flag_fell(first_i_raddr_tran)
);
ovl_implication #(
    .severity_level(severity_level),
    .property_type(`OVL_ASSERT),
    .msg({msg_prefix,"First i_raddr transaction is not pc_init after reset"}),
    .coverage_level(`OVL_COVER_NONE),
    .clock_edge(`OVL_POSEDGE),
    .reset_polarity(`OVL_ACTIVE_LOW),
    .gating_type(`OVL_GATE_NONE)
) first_i_raddr_tran_check (
    .clock(clock),
    .reset(reset),
    .enable(1'b1),
    .antecedent_expr(first_i_raddr_tran), 
    .consequent_expr(`CPU_INST.pc == `CPU_INST.pc_init),
    .fire(fire)
);
bus_channel_checker #(
    .severity_level(severity_level),
    .channel_name("i_raddr")
) i_raddr_checker (
    .clock(clock),
    .reset(reset),
    .ready(`CPU_INST.ir_addr_ready),
    .valid(`CPU_INST.ir_addr_valid)
);
bus_channel_checker #(
    .severity_level(severity_level),
    .channel_name("i_rdata")
) i_rdata_checker (
    .clock(clock),
    .reset(reset),
    .ready(`CPU_INST.ir_data_ready),
    .valid(`CPU_INST.ir_data_valid)
);
alu_checker #(
    .severity_level(severity_level)
) u_alu_checker (
    .clock(clock),
    .reset(reset)
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
edges reset_edge (
    .clock(clock),
    .reset(reset),
    .signal(reset),
    .rose(reset_rose)
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

module alu_checker(
    input clock,
    input reset,
    output wor [`OVL_FIRE_WIDTH-1:0] fire
);
parameter severity_level = `OVL_ERROR;
parameter msg_prefix = {"ALU: "};
wire alu_active;
assign alu_active = `CPU_INST.alu_din1_sel != 0 || `CPU_INST.alu_din2_sel != 0;
ovl_implication #(
    .severity_level(severity_level),
    .property_type(`OVL_ASSERT),
    .msg({msg_prefix,"add op wrong result"}),
    .coverage_level(`OVL_COVER_NONE),
    .clock_edge(`OVL_POSEDGE),
    .reset_polarity(`OVL_ACTIVE_LOW),
    .gating_type(`OVL_GATE_NONE)
) add (
    .clock(clock),
    .reset(reset),
    .enable(1'b1),
    .antecedent_expr(alu_active && `CPU_INST.alu.alu_op == `ALU_OP_ADD), 
    .consequent_expr(`CPU_INST.alu.alu_dout == (`CPU_INST.alu.alu_din1 + `CPU_INST.alu.alu_din2)),
    .fire(fire)
);
endmodule
