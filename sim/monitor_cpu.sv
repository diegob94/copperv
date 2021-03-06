`timescale 1ns/1ps
`include "testbench_h.v"
`include "copperv_h.v"

module  monitor_cpu (
    input clk,
    input rst
);
`include "monitor_utils_h.v"
`include "reg_name_h.v"
reg [`INST_WIDTH-1:0] raddr_queue[$];
always @(posedge clk) begin
    if (rst) begin
        if(`CPU_INST.ir_addr_valid && `CPU_INST.ir_addr_ready) begin
            $display($time, ": INST_FETCH: addr 0x%08X", `CPU_INST.ir_addr);
            $mon_diss(`CPU_INST.pc);
            raddr_queue.push_front(`CPU_INST.ir_addr);
        end
        if(`CPU_INST.ir_data_valid && `CPU_INST.ir_data_ready)
            $display($time, ": INST_RECV: addr 0x%08X data 0x%08X", raddr_queue.pop_back(), `CPU_INST.ir_data);
        if(`CPU_INST.inst_valid) begin
            $write($time, ": DECODER:");
            $write(" inst 0x%08X", `CPU_INST.inst);
            $write(" opcode 0x%02X", `CPU_INST.idec.opcode);
            $write(" funct 0x%01X/%0s", `CPU_INST.idec.funct, funct(`CPU_INST.idec.funct));
            $write(" imm 0x%08X", `CPU_INST.idec.imm);
            $write(" rd 0x%02X/%0s", `CPU_INST.idec.rd, reg_name(`CPU_INST.idec.rd));
            $write(" rs1 0x%02X/%0s", `CPU_INST.idec.rs1, reg_name(`CPU_INST.idec.rs1));
            $write(" rs2 0x%02X/%0s", `CPU_INST.idec.rs2, reg_name(`CPU_INST.idec.rs2));
            $write(" inst_type 0x%01X/%0s", `CPU_INST.idec.inst_type, inst_type(`CPU_INST.idec.inst_type));
            $write("\n");
        end
        if(`CPU_INST.ir_data_valid && `CPU_INST.ir_data_ready)
            $display($time, ": BUS: ir_data   : 0x%08X", `CPU_INST.ir_data);
        if(`CPU_INST.ir_addr_valid && `CPU_INST.ir_addr_ready)
            $display($time, ": BUS: ir_addr   : 0x%08X", `CPU_INST.ir_addr);
        if(`CPU_INST.dr_data_valid && `CPU_INST.dr_data_ready)
            $display($time, ": BUS: dr_data   : 0x%08X", `CPU_INST.dr_data);
        if(`CPU_INST.dr_addr_valid && `CPU_INST.dr_addr_ready)
            $display($time, ": BUS: dr_addr   : 0x%08X", `CPU_INST.dr_addr);
        if(`CPU_INST.dw_data_addr_valid && `CPU_INST.dw_data_addr_ready) begin
            $display($time, ": BUS: dw_data   : 0x%08X", `CPU_INST.dw_data);
            $display($time, ": BUS: dw_addr   : 0x%08X", `CPU_INST.dw_addr);
            $display($time, ": BUS: dw_strobe : 0x%08X", `CPU_INST.dw_strobe);
        end
        if(`CPU_INST.dw_resp_valid && `CPU_INST.dw_resp_ready)
            $display($time, ": BUS: dw_resp   : 0x%08X", `CPU_INST.dw_resp);
    end
end
always @(posedge clk) begin
    if (rst && `CPU_INST.pc_en) begin
        monitor_pc;
    end
end
always @(posedge rst) begin
    monitor_pc;
end
always @(posedge clk) begin
    if (rst) begin
        if(`CPU_INST.rd_en) begin
            $display($time, ": REGFILE: write rd addr 0x%08X/%0s data 0x%08X", `CPU_INST.rd, reg_name(`CPU_INST.rd), `CPU_INST.rd_din);
            if ($test$plusargs("DUMP_REGFILE"))
                regfile_dump;
        end
    end
end
always @(posedge clk) begin
    if (rst) begin
        if(`CPU_INST.rs1_en) begin
            $display($time, ": REGFILE: read rs1 addr 0x%08X/%0s data 0x%08X", `CPU_INST.rs1, reg_name(`CPU_INST.rs1), `CPU_INST.regfile.mem[`CPU_INST.rs1]);
        end
    end
end
always @(posedge clk) begin
    if (rst) begin
        if(`CPU_INST.rs2_en) begin
            $display($time, ": REGFILE: read rs2 addr 0x%08X/%0s data 0x%08X", `CPU_INST.rs2, reg_name(`CPU_INST.rs2), `CPU_INST.regfile.mem[`CPU_INST.rs2]);
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
            $display($time, ": ALU: din1 0x%08X din2 0x%08X dout 0x%08X comp 0x%01X op 0x%01X/%0s", `CPU_INST.alu_din1, `CPU_INST.alu_din2, `CPU_INST.alu_dout, `CPU_INST.alu_comp, `CPU_INST.alu_op, alu_op(`CPU_INST.alu_op));
    end
end

task monitor_pc;
begin
    $display($time, ": PC: 0x%08X", `CPU_INST.pc_next); 
end
endtask

task regfile_dump;
integer i;
begin
    $display($time, ": REGFILE DUMP BEGIN");
    for(i = 0; i < 2**`REG_WIDTH; i = i + 1) begin
        $display($time, ": 0x%02X %6s: 0x%08X", i[`REG_WIDTH-1:0], reg_name(i), `CPU_INST.regfile.mem[i]);
    end
    $display($time, ": REGFILE DUMP END");
end
endtask

//always @(posedge `CPU_INST.i_rdata_valid)
//    $display($time, ": i_rdata_valid asserted");
endmodule
