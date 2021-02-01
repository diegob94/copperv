`timescale 1ns/1ps
`include "testbench_h.v"
`include "copperv_h.v"

module tb();
parameter timeout = `PERIOD*10000;
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
wire [`BUS_WIDTH-1:0] ir_data;
wire [`BUS_RESP_WIDTH-1:0] dw_resp;
// copperv outputs
wire dr_data_ready;
wire dr_addr_valid;
wire dw_data_addr_valid;
wire dw_resp_ready;
wire [`BUS_WIDTH-1:0] dr_addr;
wire [`BUS_WIDTH-1:0] dw_data;
wire [`BUS_WIDTH-1:0] dw_addr;
wire [(`BUS_WIDTH/8)-1:0] dw_strobe;
wire ir_data_ready;
wire ir_addr_valid;
wire [`BUS_WIDTH-1:0] ir_addr;
initial begin
    rst = 0;
    clk = 0;
    #(`PERIOD*10);
    $display($time, ": Reset finished");
    rst = 1;
end
initial begin
    #timeout;
    $display($time, ": Simulation timeout");
    test_failed;
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
    .ir_data(ir_data),
    .dw_resp(dw_resp),
    .dr_data_ready(dr_data_ready),
    .dr_addr_valid(dr_addr_valid),
    .dw_data_addr_valid(dw_data_addr_valid),
    .dw_resp_ready(dw_resp_ready),
    .dr_addr(dr_addr),
    .dw_data(dw_data),
    .dw_addr(dw_addr),
    .dw_strobe(dw_strobe),
    .ir_data_ready(ir_data_ready),
    .ir_addr_valid(ir_addr_valid),
    .ir_addr(ir_addr)
);
sim_crossbar u_xbar (
    .clk(clk),
    .rst(rst),
    .dr_data_valid(dr_data_valid),
    .dr_addr_ready(dr_addr_ready),
    .dw_data_addr_ready(dw_data_addr_ready),
    .dw_resp_valid(dw_resp_valid),
    .dr_data(dr_data),
    .ir_data_valid(ir_data_valid),
    .ir_addr_ready(ir_addr_ready),
    .ir_data(ir_data),
    .dw_resp(dw_resp),
    .dr_data_ready(dr_data_ready),
    .dr_addr_valid(dr_addr_valid),
    .dw_data_addr_valid(dw_data_addr_valid),
    .dw_resp_ready(dw_resp_ready),
    .dr_addr(dr_addr),
    .dw_data(dw_data),
    .dw_addr(dw_addr),
    .dw_strobe(dw_strobe),
    .ir_data_ready(ir_data_ready),
    .ir_addr_valid(ir_addr_valid),
    .ir_addr(ir_addr)
);
monitor_cpu mon(
    .clk(clk),
    .rst(rst)
);
`ifdef ENABLE_CHECKER
checker_cpu chk(
    .clock(clk),
    .reset(rst)
);
`endif
integer f;
`STRING vcd_file;
initial begin
    if (!$value$plusargs("VCD_FILE=%s", vcd_file)) begin
        vcd_file = "tb.vcd";
    end
    $dumpfile(vcd_file);
    $dumpvars(0, tb);
    f = $fopen("fake_uart.log","w");
end
always @(posedge clk)
    if(dw_data_addr_valid && dw_data_addr_ready) begin
        case (dw_addr)
            32'h8000: begin
                case (dw_data)
                    32'h01000001: test_passed;
                    32'h02000001: test_failed;
                    default: test_failed;
                endcase
            end
            32'h8004: $fwrite(f, "%c", dw_data[7:0]);
        endcase
    end

task test_passed;
begin
    $display($time, ": TEST PASSED");
    finish_sim;
end
endtask
task test_failed;
reg [`DATA_WIDTH-1:0] test_id;
begin
    test_id = `CPU_INST.regfile.mem[`REG_T3];
    $display($time, ": TEST FAILED: instruction_id: %0d test_id: %0d", test_id[31:16], test_id[15:0]);
    finish_sim;
end
endtask
task finish_sim;
begin
    $fwrite(f, "\n");
    $fclose(f);  
    $finish;
end
endtask
endmodule

