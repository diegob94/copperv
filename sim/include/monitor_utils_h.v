// File generated by monitor_utils.py 2020-07-04 02:57:26.386987

function `STRING state;
input [`STATE_WIDTH-1:0] arg;
begin
    case (arg)
        `STATE_RESET:
            state = "RESET";
        `STATE_IDLE:
            state = "IDLE";
        `STATE_FETCH:
            state = "FETCH";
        `STATE_DECODE:
            state = "DECODE";
        `STATE_EXEC:
            state = "EXEC";
        `STATE_MEM:
            state = "MEM";
        default:
            state = "UNKNOWN";
    endcase
end
endfunction

function `STRING inst_type;
input [`INST_TYPE_WIDTH-1:0] arg;
begin
    case (arg)
        `INST_TYPE_IMM:
            inst_type = "IMM";
        `INST_TYPE_INT_IMM:
            inst_type = "INT_IMM";
        `INST_TYPE_INT_REG:
            inst_type = "INT_REG";
        `INST_TYPE_BRANCH:
            inst_type = "BRANCH";
        `INST_TYPE_STORE:
            inst_type = "STORE";
        `INST_TYPE_JAL:
            inst_type = "JAL";
        default:
            inst_type = "UNKNOWN";
    endcase
end
endfunction

function `STRING funct;
input [`FUNCT_WIDTH-1:0] arg;
begin
    case (arg)
        `FUNCT_ADD:
            funct = "ADD";
        `FUNCT_SUB:
            funct = "SUB";
        `FUNCT_EQ:
            funct = "EQ";
        `FUNCT_NEQ:
            funct = "NEQ";
        `FUNCT_MEM_BYTE:
            funct = "MEM_BYTE";
        `FUNCT_MEM_HWORD:
            funct = "MEM_HWORD";
        `FUNCT_MEM_WORD:
            funct = "MEM_WORD";
        `FUNCT_JAL:
            funct = "JAL";
        default:
            funct = "UNKNOWN";
    endcase
end
endfunction

function `STRING pc_next_sel;
input [`PC_NEXT_SEL_WIDTH-1:0] arg;
begin
    case (arg)
        `PC_NEXT_SEL_STALL:
            pc_next_sel = "STALL";
        `PC_NEXT_SEL_INCR:
            pc_next_sel = "INCR";
        `PC_NEXT_SEL_ADD_IMM:
            pc_next_sel = "ADD_IMM";
        default:
            pc_next_sel = "UNKNOWN";
    endcase
end
endfunction

function `STRING alu_op;
input [`ALU_OP_WIDTH-1:0] arg;
begin
    case (arg)
        `ALU_OP_NOP:
            alu_op = "NOP";
        `ALU_OP_ADD:
            alu_op = "ADD";
        `ALU_OP_SUB:
            alu_op = "SUB";
        `ALU_OP_EQ:
            alu_op = "EQ";
        `ALU_OP_NEQ:
            alu_op = "NEQ";
        default:
            alu_op = "UNKNOWN";
    endcase
end
endfunction

function `STRING dissassembly;
input [`PC_WIDTH-1:0] arg;
begin
    case (arg)
        32'h0:
            dissassembly = "0:   075bd337  lui   t1,0x75bd";
        32'h4:
            dissassembly = "4:   d1530313  addi  t1,t1,-747 # 75bcd15 <end+0x75bcce5>";
        32'h8:
            dissassembly = "8:   02100393  addi  t2,zero,33";
        32'hc:
            dissassembly = "c:   06500e13  addi  t3,zero,101";
        32'h10:
            dissassembly = "10:  0ca00e93  addi  t4,zero,202";
        32'h14:
            dissassembly = "14:  01de0f33  add   t5,t3,t4";
        32'h18:
            dissassembly = "18:  12f00e13  addi  t3,zero,303";
        32'h1c:
            dissassembly = "1c:  41cf0fb3  sub   t6,t5,t3";
        32'h20:
            dissassembly = "20:  000f8463  beq   t6,zero,28 <finish>";
        32'h24:
            dissassembly = "24:  00000313  addi  t1,zero,0";
        32'h28:
            dissassembly = "28:  0063a023  sw    t1,0(t2)";
        32'h2c:
            dissassembly = "2c:  0000006f  jal   zero,2c <loop>";
        default:
            dissassembly = "UNKNOWN";
    endcase
end
endfunction
