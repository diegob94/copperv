`timescale 1ns/1ps
`include "testbench_h.v"
`include "copperv_h.v"

module tb();
parameter timeout = `PERIOD*100;
// copperv inputs
reg clk;
reg rst;
wire dr_data_valid;
wire dr_addr_ready;
wire dw_data_addr_ready;
wire dw_resp_valid;
wire [`BUS_WIDTH-1:0] dr_data;
wire ir_data_valid;
wire ir_addr_ready;
wire iw_data_addr_ready;
wire iw_resp_valid;
wire [`BUS_WIDTH-1:0] ir_data;
wire [`BUS_RESP_WIDTH-1:0] iw_resp;
wire [`BUS_RESP_WIDTH-1:0] dw_resp;
// copperv outputs
wire dr_data_ready;
wire dr_addr_valid;
wire dw_data_addr_valid;
wire dw_resp_ready;
wire [`BUS_WIDTH-1:0] dr_addr;
wire [`BUS_WIDTH-1:0] dw_data;
wire [`BUS_WIDTH-1:0] dw_addr;
wire ir_data_ready;
wire ir_addr_valid;
wire iw_data_addr_valid;
wire iw_resp_ready;
wire [`BUS_WIDTH-1:0] ir_addr;
wire [`BUS_WIDTH-1:0] iw_data;
wire [`BUS_WIDTH-1:0] iw_addr;
initial begin
    rst = 0;
    clk = 0;
    #(`PERIOD*10);
    $display($time, ": Reset finished");
    rst = 1;
end
initial begin
    #timeout;
    $display($time, ": Failed: Timeout");
    finish_sim;
end
always #(`PERIOD/2) clk <= !clk;
copperv dut (
    .clk(clk),
    .rst(rst),
    .dr_data_valid(dr_data_valid),
    .dr_addr_ready(dr_addr_ready),
    .dw_data_addr_ready(dw_data_addr_ready),
    .dw_resp_valid(dw_resp_valid),
    .dr_data(dr_data),
    .ir_data_valid(ir_data_valid),
    .ir_addr_ready(ir_addr_ready),
    .iw_data_addr_ready(iw_data_addr_ready),
    .iw_resp_valid(iw_resp_valid),
    .ir_data(ir_data),
    .iw_resp(iw_resp),
    .dw_resp(dw_resp),
    .dr_data_ready(dr_data_ready),
    .dr_addr_valid(dr_addr_valid),
    .dw_data_addr_valid(dw_data_addr_valid),
    .dw_resp_ready(dw_resp_ready),
    .dr_addr(dr_addr),
    .dw_data(dw_data),
    .dw_addr(dw_addr),
    .ir_data_ready(ir_data_ready),
    .ir_addr_valid(ir_addr_valid),
    .iw_data_addr_valid(iw_data_addr_valid),
    .iw_resp_ready(iw_resp_ready),
    .ir_addr(ir_addr),
    .iw_data(iw_data),
    .iw_addr(iw_addr)
);
native_memory #(.instruction_memory(`TRUE)) i_mem(
    .clk(clk),
    .rst(rst),
    .r_addr_valid(ir_addr_valid),
    .r_data_ready(ir_data_ready),
    .w_data_addr_valid(iw_data_addr_valid),
    .r_addr(ir_addr),
    .w_data(iw_data),
    .w_addr(iw_addr),
    .w_resp_ready(iw_resp_ready),
    .w_resp_valid(iw_resp_valid),
    .w_resp(iw_resp),
    .r_addr_ready(ir_addr_ready),
    .r_data_valid(ir_data_valid),
    .w_data_addr_ready(iw_data_addr_ready),
    .r_data(ir_data)
);
native_memory d_mem(
    .clk(clk),
    .rst(rst),
    .r_addr_valid(dr_addr_valid),
    .r_data_ready(dr_data_ready),
    .w_data_addr_valid(dw_data_addr_valid),
    .r_addr(dr_addr),
    .w_data(dw_data),
    .w_addr(dw_addr),
    .w_resp_ready(dw_resp_ready),
    .w_resp_valid(dw_resp_valid),
    .w_resp(dw_resp),
    .r_addr_ready(dr_addr_ready),
    .r_data_valid(dr_data_valid),
    .w_data_addr_ready(dw_data_addr_ready),
    .r_data(dr_data)
);
monitor_cpu mon(
    .clk(clk),
    .rst(rst)
);
checker_cpu chk(
    .clock(clk),
    .reset(rst)
);

initial begin
    $dumpfile("tb.lxt");
    $dumpvars(0, tb);
end

task finish_sim;
begin
    $finish;
end
endtask

endmodule

