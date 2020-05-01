`timescale 1ns/1ps

`define STRING reg [1023:0]
`define PERIOD 10
`define TRUE 1
`define FALSE 0
`define CPU_INST tb.dut

module tb();
parameter bus_width = 32;
parameter timeout = `PERIOD*50;
reg clk;
reg rst;
wire d_rdata_valid;
wire d_raddr_ready;
wire d_wdata_ready;
wire d_waddr_ready;
wire [bus_width-1:0] d_rdata;
wire i_rdata_valid;
wire i_raddr_ready;
wire i_wdata_ready;
wire i_waddr_ready;
wire [bus_width-1:0] i_rdata;
wire d_rdata_ready;
wire d_raddr_valid;
wire d_wdata_valid;
wire d_waddr_valid;
wire [bus_width-1:0] d_raddr;
wire [bus_width-1:0] d_wdata;
wire [bus_width-1:0] d_waddr;
wire i_rdata_ready;
wire i_raddr_valid;
wire i_wdata_valid;
wire i_waddr_valid;
wire [bus_width-1:0] i_raddr;
wire [bus_width-1:0] i_wdata;
wire [bus_width-1:0] i_waddr;
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
    $finish;
end
always #(`PERIOD/2) clk <= !clk;
copperv dut(
    .clk(clk),
    .rst(rst),
    .d_rdata_valid(d_rdata_valid),
    .d_raddr_ready(d_raddr_ready),
    .d_wdata_ready(d_wdata_ready),
    .d_waddr_ready(d_waddr_ready),
    .d_rdata(d_rdata),
    .i_rdata_valid(i_rdata_valid),
    .i_raddr_ready(i_raddr_ready),
    .i_wdata_ready(i_wdata_ready),
    .i_waddr_ready(i_waddr_ready),
    .i_rdata(i_rdata),
    .d_rdata_ready(d_rdata_ready),
    .d_raddr_valid(d_raddr_valid),
    .d_wdata_valid(d_wdata_valid),
    .d_waddr_valid(d_waddr_valid),
    .d_raddr(d_raddr),
    .d_wdata(d_wdata),
    .d_waddr(d_waddr),
    .i_rdata_ready(i_rdata_ready),
    .i_raddr_valid(i_raddr_valid),
    .i_wdata_valid(i_wdata_valid),
    .i_waddr_valid(i_waddr_valid),
    .i_raddr(i_raddr),
    .i_wdata(i_wdata),
    .i_waddr(i_waddr)
);
native_memory #(.instruction_memory(`TRUE)) i_mem(
    .clk(clk),
    .rst(rst),
    .rdata_valid(i_rdata_valid),
    .raddr_ready(i_raddr_ready),
    .wdata_ready(i_wdata_ready),
    .waddr_ready(i_waddr_ready),
    .rdata(i_rdata),
    .rdata_ready(i_rdata_ready),
    .raddr_valid(i_raddr_valid),
    .wdata_valid(i_wdata_valid),
    .waddr_valid(i_waddr_valid),
    .raddr(i_raddr),
    .wdata(i_wdata),
    .waddr(i_waddr)
);
native_memory d_mem(
    .clk(clk),
    .rst(rst),
    .rdata_valid(d_rdata_valid),
    .raddr_ready(d_raddr_ready),
    .wdata_ready(d_wdata_ready),
    .waddr_ready(d_waddr_ready),
    .rdata(d_rdata),
    .rdata_ready(d_rdata_ready),
    .raddr_valid(d_raddr_valid),
    .wdata_valid(d_wdata_valid),
    .waddr_valid(d_waddr_valid),
    .raddr(d_raddr),
    .wdata(d_wdata),
    .waddr(d_waddr)
);
monitor_cpu mon(
    .clk(clk),
    .rst(rst)
);
endmodule

module  monitor_cpu #(
    parameter inst_width = 32
) (
    input clk,
    input rst
);
reg [inst_width-1:0] raddr_queue;
always @(posedge clk) begin
    if (rst) begin
        $display($time, ": PC: %d", `CPU_INST.pc);
        if(`CPU_INST.i_raddr_valid) begin
            $display($time, ": INST_FETCH: addr 0x%08X", `CPU_INST.i_raddr);
            raddr_queue = `CPU_INST.i_raddr;
        end
        if(`CPU_INST.i_rdata_valid && `CPU_INST.i_rdata_ready)
            $display($time, ": INST_RECV: addr 0x%08X data 0x%08X", raddr_queue, `CPU_INST.i_rdata);
        if(`CPU_INST.inst_valid) begin
            $write($time, ": DECODER:");
            $write(" inst 0x%08X", `CPU_INST.inst);
            $write(" opcode 0x%02X", `CPU_INST.idec.opcode);
            $write(" funct 0x%01X", `CPU_INST.idec.funct);
            $write(" imm 0x%08X", `CPU_INST.idec.imm);
            $write(" rd 0x%02X", `CPU_INST.idec.rd);
            $write(" rs1 0x%02X", `CPU_INST.idec.rs1);
            $write(" rs2 0x%02X", `CPU_INST.idec.rs2);
            $write(" type_imm 0x%01X", `CPU_INST.idec.type_imm);
            $write(" type_int_imm 0x%01X", `CPU_INST.idec.type_int_imm);
            $write(" type_int_reg 0x%01X", `CPU_INST.idec.type_int_reg);
            $write(" type_branch 0x%01X", `CPU_INST.idec.type_branch);
            $write("\n");
        end
        if(`CPU_INST.i_raddr_valid && `CPU_INST.i_raddr_ready)
            $display($time, ": BUS: i_raddr tran: 0x%08X", `CPU_INST.i_raddr);
        if(`CPU_INST.i_rdata_valid && `CPU_INST.i_rdata_ready)
            $display($time, ": BUS: i_rdata tran: 0x%08X", `CPU_INST.i_rdata);
        if(`CPU_INST.rd_en)
            $display($time, ": REGFILE: addr 0x%08X data 0x%08X", `CPU_INST.rd, `CPU_INST.rd_din);
    end
end
//always @(posedge `CPU_INST.i_rdata_valid)
//    $display($time, ": i_rdata_valid asserted");
endmodule
