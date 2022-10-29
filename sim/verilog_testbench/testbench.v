`timescale 1ns/1ps

`define STRING              reg [1023:0]
`define TRUE                1
`define FALSE               0

`include "magic_constants_h.v"
`include "copperv_h.v"

module tb(
`ifdef VERILATOR
    input clk,
    input rst
`endif
);
parameter period = 10;
parameter timeout = 430000*period;
reg finish_cocotb = 0;
// copperv inputs
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
`ifndef VERILATOR
reg clk;
reg rst;
initial begin
    rst = 0;
    clk = 0;
    #(period*10);
    $display($time, ": Reset finished");
    rst = 1;
end
always #(period/2) clk <= !clk;
`endif
initial begin
    if ($test$plusargs("disable_timeout") == 0) begin
        $display($time, ": timeout = %0d",timeout);
        #(timeout);
        $display($time, ": Simulation timeout");
        test_failed;
    end
end
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
fake_memory fake_mem (
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
integer fake_uart_fp;
`STRING vcd_file;
initial begin
    if (!$value$plusargs("VCD_FILE=%s", vcd_file)) begin
        vcd_file = "tb.vcd";
    end
    $dumpfile(vcd_file);
    $dumpvars(0, tb);
    fake_uart_fp = $fopen("fake_uart.log","w");
end
reg [`DATA_WIDTH-1:0] timer_counter;
initial timer_counter = 0;
reg flag = 0;
// Fake IO
always @(posedge clk) begin
    // Output
    if(dw_data_addr_valid && dw_data_addr_ready) begin
        case (dw_addr)
            `T_ADDR: begin
                case (dw_data)
                    `T_PASS: test_passed;
                    `T_FAIL: test_failed;
                    default: test_failed;
                endcase
            end
            `O_ADDR: begin
                $fwrite(fake_uart_fp, "%c", dw_data[7:0]);
                if(dw_data[7:0] == "\n")
                    $fflush(fake_uart_fp);
            end
        endcase
    end
    // Input
    if(dr_addr_valid && dr_addr_ready) begin
        case (dr_addr)
            `TC_ADDR: begin
                force dr_data = timer_counter;
                force dr_data_valid = 1;
                flag = 1;
                if ($test$plusargs("debug_testbench") > 0) begin
                    $display($time, ": read timer_counter: %0d", timer_counter);
                end
            end
        endcase
    end else if (flag) begin
        release dr_data;
        release dr_data_valid;
        flag = 0;
    end
    timer_counter = timer_counter + 1;
end

task test_passed;
begin
    $display($time, ": TEST PASSED");
    finish_sim;
end
endtask
task test_failed;
begin
    $display($time, ": TEST FAILED");
    finish_sim;
end
endtask
task finish_sim;
begin
    $fwrite(fake_uart_fp, "\n# copperv testbench finished\n");
    $fclose(fake_uart_fp);  
    if ($test$plusargs("cocotb") > 0) begin
        finish_cocotb = 1;
    end else begin
        $finish;
    end
end
endtask
endmodule

