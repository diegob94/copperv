`timescale 1ns/1ps

`define UNSIGNED(x,wlhs,high,low) {{(wlhs-(high-low+1)){1'b0}},x[high:low]}

module idecoder import copperv_pkg::*;
  (
    input [inst_width-1:0] inst,
    output reg [imm_width-1:0] imm,
    output inst_type_e inst_type,
    output reg_adr_td rd,
    output reg_adr_td rs1,
    output reg_adr_td rs2,
    output funct_e funct
  );
  opcode_e opcode;
  reg [funct3_width-1:0] funct3;
  reg [funct7_width-1:0] funct7;
  always @(*) begin
      inst_type = inst_type_e'(0);
      funct = funct_e'(0);
      imm = 0;
      rs1 = 0;
      rs2 = 0;
      rd = 0;
      funct3 = 0;
      funct7 = 0;
      opcode = opcode_e'(inst[6:0]);
      case (opcode)
        opcode_lui: begin
          inst_type = inst_type_imm;
          decode_u_type(inst[inst_width-1:7]);
        end
        opcode_jal: begin
          inst_type = inst_type_jal;
          decode_j_type(inst[inst_width-1:7]);
        end
        opcode_jalr: begin
          inst_type = inst_type_jalr;
          decode_i_type(inst[inst_width-1:7]);
        end
        opcode_auipc: begin
          inst_type = inst_type_auipc;
          decode_u_type(inst[inst_width-1:7]);
        end
        opcode_int_imm: begin
            inst_type = inst_type_int_imm;
            decode_i_type(inst[inst_width-1:7]);
            case (funct3)
                3'd0: funct = funct_add;
                3'd1: funct = funct_sll;
                3'd2: funct = funct_slt;
                3'd3: funct = funct_sltu;
                3'd4: funct = funct_xor;
                3'd5: begin
                    case(imm[11:5])
                        7'd0:  funct = funct_srl;
                        7'd32: funct = funct_sra;
                        default: ;
                    endcase
                    imm = `UNSIGNED(imm,32,4,0);
                end
                3'd6: funct = funct_or;
                3'd7: funct = funct_and;
            endcase
        end
        opcode_int_reg: begin 
            inst_type = inst_type_int_reg;
            decode_r_type(inst[inst_width-1:7]);
            case ({funct7, funct3})
                {7'd0,  3'd0}: funct = funct_add;
                {7'd32, 3'd0}: funct = funct_sub;
                {7'd0,  3'd1}: funct = funct_sll;
                {7'd0,  3'd2}: funct = funct_slt;
                {7'd0,  3'd3}: funct = funct_sltu;
                {7'd0,  3'd4}: funct = funct_xor;
                {7'd0,  3'd5}: funct = funct_srl;
                {7'd32, 3'd5}: funct = funct_sra;
                {7'd0,  3'd6}: funct = funct_or;
                {7'd0,  3'd7}: funct = funct_and;
                default: ;
            endcase
        end
        opcode_branch: begin
            inst_type = inst_type_branch;
            decode_b_type(inst[inst_width-1:7]);
            case (funct3)
                3'd0: funct = funct_eq;
                3'd1: funct = funct_neq;
                3'd4: funct = funct_lt;
                3'd5: funct = funct_gte;
                3'd6: funct = funct_ltu;
                3'd7: funct = funct_gteu;
                default: ;
            endcase
        end
        opcode_store: begin
            inst_type = inst_type_store;
            decode_s_type(inst[inst_width-1:7]);
            case(funct3)
                3'd0: funct = funct_mem_byte;
                3'd1: funct = funct_mem_hword;
                3'd2: funct = funct_mem_word;
                default: ;
            endcase
        end
        opcode_load: begin
            inst_type = inst_type_load;
            decode_i_type(inst[inst_width-1:7]);
            case(funct3)
                3'd0: funct = funct_mem_byte;
                3'd1: funct = funct_mem_hword;
                3'd2: funct = funct_mem_word;
                3'd4: funct = funct_mem_byteu;
                3'd5: funct = funct_mem_hwordu;
                default: ;
            endcase
        end
        opcode_fence: begin
            inst_type = inst_type_fence;
        end
        default: ;
    endcase
  end
  task decode_u_type;
      input [inst_width-1:7] inst_t;
      begin
          imm = {inst_t[31:12], 12'b0};
          rd = inst_t[11:7];
      end
  endtask
  task decode_j_type;
      input [inst_width-1:7] inst_t;
      begin
          imm = {{12{inst_t[31]}}, inst_t[19:12], inst_t[20], inst_t[30:25], inst_t[24:21], 1'b0};
          rd = inst_t[11:7];
      end
  endtask
  task decode_i_type;
      input [inst_width-1:7] inst_t;
      begin
          imm = {{21{inst_t[31]}}, inst_t[30:20]};
          rd = inst_t[11:7];
          rs1 = inst_t[19:15];
          funct3 = inst_t[14:12];
      end
  endtask
  task decode_r_type;
      input [inst_width-1:7] inst_t;
      begin
          rs1 = inst_t[19:15];
          rs2 = inst_t[24:20];
          rd = inst_t[11:7];
          funct7 = inst_t[31:25];
          funct3 = inst_t[14:12];
      end
  endtask
  task decode_b_type;
      input [inst_width-1:7] inst_t;
      begin
          imm = {{20{inst_t[31]}}, inst_t[7], inst_t[30:25], inst_t[11:8], 1'b0};
          rs1 = inst_t[19:15];
          rs2 = inst_t[24:20];
          funct3 = inst_t[14:12];
      end
  endtask
  task decode_s_type;
      input [inst_width-1:7] inst_t;
      begin
          imm = {{21{inst_t[31]}}, inst_t[30:25], inst_t[11:7]};
          rs1 = inst_t[19:15];
          rs2 = inst_t[24:20];
          funct3 = inst_t[14:12];
      end
  endtask
endmodule
