`timescale 1ns/1ps
`include "copperv_h.v"

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
            $write(" inst_type %0s", inst_type(`CPU_INST.idec.inst_type));
            $write("\n");
        end
        if(`CPU_INST.i_raddr_valid && `CPU_INST.i_raddr_ready)
            $display($time, ": BUS: i_raddr tran: 0x%08X", `CPU_INST.i_raddr);
        if(`CPU_INST.i_rdata_valid && `CPU_INST.i_rdata_ready)
            $display($time, ": BUS: i_rdata tran: 0x%08X", `CPU_INST.i_rdata);
        if(`CPU_INST.rd_en)
            $display($time, ": REGFILE: rd addr 0x%08X data 0x%08X", `CPU_INST.rd, `CPU_INST.rd_din);
    end
end
reg rs1_queue;
always @(posedge clk) begin
    if (rst) begin
        if(`CPU_INST.rs1_en) begin
            rs1_queue = `CPU_INST.rs1;
            @(posedge clk);
            $display($time, ": REGFILE: rs1 addr 0x%08X data 0x%08X", rs1_queue, `CPU_INST.rs1_dout);
        end
    end
end
reg rs2_queue;
always @(posedge clk) begin
    if (rst) begin
        if(`CPU_INST.rs2_en) begin
            rs2_queue = `CPU_INST.rs2;
            @(posedge clk);
            $display($time, ": REGFILE: rs2 addr 0x%08X data 0x%08X", rs2_queue, `CPU_INST.rs2_dout);
        end
    end
end
always @(posedge clk) begin
    if (rst) begin
        $display($time, ": CONTROL: state %8s next %8s", control_state(`CPU_INST.control.state), control_state(`CPU_INST.control.state_next));
    end
end

function `STRING control_state;
input [`STATE_WIDTH-1:0] s;
begin
    case (s)
        `FETCH_S:
            control_state = "FETCH";
        `LOAD_S:
            control_state = "LOAD";
        `EXEC_S:
            control_state = "EXEC";
        `MEM_S:
            control_state = "MEM";
        default:
            control_state = "UNKNOWN";
    endcase
end
endfunction

function `STRING inst_type;
input [`INST_TYPE_WIDTH-1:0] s;
begin
    case (s)
        `INST_TYPE_IMM:
            inst_type = "IMM";
        `INST_TYPE_INT_IMM:
            inst_type = "INT_IMM";
        `INST_TYPE_INT_REG:
            inst_type = "INT_REG";
        `INST_TYPE_BRANCH:
            inst_type = "BRANCH";
        default:
            inst_type = "UNKNOWN";
    endcase
end
endfunction

//always @(posedge `CPU_INST.i_rdata_valid)
//    $display($time, ": i_rdata_valid asserted");
endmodule
