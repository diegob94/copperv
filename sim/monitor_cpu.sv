`timescale 1ns/1ps
`include "testbench_h.v"
`include "copperv_h.v"

module  monitor_cpu (
    input clk,
    input rst
);
`include "magic_numbers_h.v"
`include "reg_name_h.v"
reg [`INST_WIDTH-1:0] raddr_queue[$];
always @(posedge clk) begin
    if (rst) begin
        if(`CPU_INST.i_raddr_valid) begin
            $display($time, ": INST_FETCH: addr 0x%08X", `CPU_INST.i_raddr);
            raddr_queue.push_front(`CPU_INST.i_raddr);
        end
        if(`CPU_INST.i_rdata_valid && `CPU_INST.i_rdata_ready)
            $display($time, ": INST_RECV: addr 0x%08X data 0x%08X", raddr_queue.pop_back(), `CPU_INST.i_rdata);
        if(`CPU_INST.inst_valid) begin
            $write($time, ": DECODER:");
            $write(" inst 0x%08X", `CPU_INST.inst);
            $write(" opcode 0x%02X", `CPU_INST.idec.opcode);
            $write(" funct 0x%01X", `CPU_INST.idec.funct);
            $write(" imm 0x%08X", `CPU_INST.idec.imm);
            $write(" rd 0x%02X %0s", `CPU_INST.idec.rd, reg_name(`CPU_INST.idec.rd));
            $write(" rs1 0x%02X %0s", `CPU_INST.idec.rs1, reg_name(`CPU_INST.idec.rs1));
            $write(" rs2 0x%02X %0s", `CPU_INST.idec.rs2, reg_name(`CPU_INST.idec.rs2));
            $write(" inst_type %0s", inst_type(`CPU_INST.idec.inst_type));
            $write("\n");
        end
        if(`CPU_INST.i_raddr_valid && `CPU_INST.i_raddr_ready)
            $display($time, ": BUS: i_raddr tran: 0x%08X", `CPU_INST.i_raddr);
        if(`CPU_INST.i_rdata_valid && `CPU_INST.i_rdata_ready)
            $display($time, ": BUS: i_rdata tran: 0x%08X", `CPU_INST.i_rdata);
    end
end
always @(`CPU_INST.pc, posedge `CPU_INST.rst) begin
    if (rst) begin
        $display($time, ": PC: %d", `CPU_INST.pc);
    end
end
always @(posedge clk) begin
    if (rst) begin
        if(`CPU_INST.rd_en) begin
            @(posedge clk);
            $display($time, ": REGFILE: write rd addr 0x%08X %0s data 0x%08X", `CPU_INST.rd, reg_name(`CPU_INST.rd), `CPU_INST.rd_din);
            //tb.regfile_dump;
        end
    end
end
reg [`REG_WIDTH-1:0] rs1_queue;
always @(posedge clk) begin
    if (rst) begin
        if(`CPU_INST.rs1_en) begin
            rs1_queue = `CPU_INST.rs1;
            @(posedge clk);
            $display($time, ": REGFILE: read rs1 addr 0x%08X %0s data 0x%08X", rs1_queue, reg_name(rs1_queue), `CPU_INST.rs1_dout);
        end
    end
end
reg [`REG_WIDTH-1:0] rs2_queue;
always @(posedge clk) begin
    if (rst) begin
        if(`CPU_INST.rs2_en) begin
            rs2_queue = `CPU_INST.rs2;
            @(posedge clk);
            $display($time, ": REGFILE: read rs2 addr 0x%08X %0s data 0x%08X", rs2_queue, reg_name(rs2_queue), `CPU_INST.rs2_dout);
        end
    end
end
always @(posedge clk) begin
    if (rst) begin
        $display($time, ": CONTROL: state %8s next %8s", state(`CPU_INST.control.state), state(`CPU_INST.control.state_next));
    end
end
always @(posedge clk) begin
    if (rst) begin
        if (`CPU_INST.alu_din1_sel != 0 || `CPU_INST.alu_din2_sel != 0)
            $display($time, ": ALU: din1 0x%08X din2 0x%08X dout 0x%08X funct 0x%01X", `CPU_INST.alu_din1, `CPU_INST.alu_din2, `CPU_INST.alu_dout, `CPU_INST.funct);
    end
end

task regfile_dump;
integer i;
begin
    $display($time, ": REGFILE DUMP BEGIN");
    for(i = 0; i < 2**`REG_WIDTH; i = i + 1) begin
        $display($time, ": 0x%02X %6s: 0x%08X", i[`REG_WIDTH-1:0], reg_name(i), `CPU_INST.regfile.memory[i]);
    end
    $display($time, ": REGFILE DUMP END");
end
endtask

//always @(posedge `CPU_INST.i_rdata_valid)
//    $display($time, ": i_rdata_valid asserted");
endmodule
