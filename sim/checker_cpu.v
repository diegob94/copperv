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
    .channel_name("ir_addr")
) ir_addr_checker (
    .clock(clock),
    .reset(reset),
    .ready(`CPU_INST.ir_addr_ready),
    .valid(`CPU_INST.ir_addr_valid),
    .payload(`CPU_INST.ir_addr)
);
bus_channel_checker #(
    .severity_level(severity_level),
    .channel_name("ir_data")
) ir_data_checker (
    .clock(clock),
    .reset(reset),
    .ready(`CPU_INST.ir_data_ready),
    .valid(`CPU_INST.ir_data_valid),
    .payload(`CPU_INST.ir_data)
);
bus_channel_checker #(
    .severity_level(severity_level),
    .channel_name("dr_data"),
    .range_property_type(`OVL_ASSERT_2STATE)
) dr_data_checker (
    .clock(clock),
    .reset(reset),
    .ready(`CPU_INST.dr_data_ready),
    .valid(`CPU_INST.dr_data_valid),
    .payload(`CPU_INST.dr_data)
);
bus_channel_checker #(
    .severity_level(severity_level),
    .channel_name("dr_addr")
) dr_addr_checker (
    .clock(clock),
    .reset(reset),
    .ready(`CPU_INST.dr_addr_ready),
    .valid(`CPU_INST.dr_addr_valid),
    .payload(`CPU_INST.dr_addr)
);
bus_channel_checker #(
    .payload_max(2**`FAKE_MEM_ADDR_WIDTH),
    .severity_level(severity_level),
    .channel_name("dw_data_addr")
) dw_data_addr_checker (
    .clock(clock),
    .reset(reset),
    .ready(`CPU_INST.dw_data_addr_ready),
    .valid(`CPU_INST.dw_data_addr_valid),
    .payload(`CPU_INST.dw_addr)
);
bus_channel_checker #(
    .payload_width(`BUS_RESP_WIDTH),
    .severity_level(severity_level),
    .channel_name("dw_resp")
) dw_resp_checker (
    .clock(clock),
    .reset(reset),
    .ready(`CPU_INST.dw_resp_ready),
    .valid(`CPU_INST.dw_resp_valid),
    .payload(`CPU_INST.dw_resp)
);
alu_checker #(
    .severity_level(severity_level)
) u_alu_checker (
    .clock(clock),
    .reset(reset)
);
endmodule

module bus_channel_checker #(
    parameter payload_width = `BUS_WIDTH
) (
    input clock,
    input reset,
    input valid,
    input ready,
    input [payload_width-1:0] payload,
    output wor [`OVL_FIRE_WIDTH-1:0] fire
);
parameter range_property_type = `OVL_ASSERT;
parameter payload_min = 0;
parameter payload_max = {payload_width{1'b1}};
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
) reset_valid (
    .clock(clock),
    .reset(reset),
    .enable(1'b1),
    .antecedent_expr(reset_rose), 
    .consequent_expr(!valid),
    .fire(fire)
);
ovl_implication #(
    .severity_level(severity_level),
    .property_type(`OVL_ASSERT),
    .msg({msg_prefix,"ready invalid after reset"}),
    .coverage_level(`OVL_COVER_NONE),
    .clock_edge(`OVL_POSEDGE),
    .reset_polarity(`OVL_ACTIVE_LOW),
    .gating_type(`OVL_GATE_NONE)
) reset_ready (
    .clock(clock),
    .reset(reset),
    .enable(1'b1),
    .antecedent_expr(reset_rose), 
    .consequent_expr(ready | !ready),
    .fire(fire)
);
ovl_never_unknown #(
    .severity_level(severity_level),
    .property_type(`OVL_ASSERT),
    .msg({msg_prefix,"ready invalid state (non 0 or 1)"}),
    .coverage_level(`OVL_COVER_NONE),
    .clock_edge(`OVL_POSEDGE),
    .reset_polarity(`OVL_ACTIVE_LOW),
    .gating_type(`OVL_GATE_NONE)
) ready_never_unknown (
    .clock(clock), 
    .reset(reset), 
    .enable(1'b1), 
    .qualifier(1'b1),
    .test_expr(ready), 
    .fire(fire)
);
ovl_never_unknown #(
    .severity_level(severity_level),
    .property_type(`OVL_ASSERT),
    .msg({msg_prefix,"valid invalid state (non 0 or 1)"}),
    .coverage_level(`OVL_COVER_NONE),
    .clock_edge(`OVL_POSEDGE),
    .reset_polarity(`OVL_ACTIVE_LOW),
    .gating_type(`OVL_GATE_NONE)
) valid_never_unknown (
    .clock(clock), 
    .reset(reset), 
    .enable(1'b1), 
    .qualifier(1'b1),
    .test_expr(valid), 
    .fire(fire)
);
ovl_range #(
    .severity_level(severity_level),
    .width(payload_width),
    .min(payload_min),
    .max(payload_max),
    .property_type(range_property_type),
    .msg({msg_prefix,"payload out of range"}),
    .coverage_level(`OVL_COVER_NONE),
    .clock_edge(`OVL_POSEDGE),
    .reset_polarity(`OVL_ACTIVE_LOW),
    .gating_type(`OVL_GATE_CLOCK)
) payload_range (
    .clock(clock),
    .reset(reset),
    .enable(ready && valid),
    .test_expr(payload),
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
