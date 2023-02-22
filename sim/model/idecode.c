#include <stdio.h>
#include "copperv_sim.h"

void decode_u_type(instruction_t instruction, instruction_s *decoded_instruction) {
    decoded_instruction->imm = GET_BITS(instruction,31,12) << 12;
    decoded_instruction->rd = GET_BITS(instruction,11,7);
    decoded_instruction->funct = FUNCT_ADD;
}

void decode_j_type(instruction_t instruction, instruction_s *decoded_instruction) {
    decoded_instruction->imm = (REPLICATE_BIT(GET_BIT(instruction, 31), 12) << 20) \
            | (GET_BITS(instruction, 19, 12) << 12) \
            | (GET_BIT(instruction, 20) << 11) \
            | (GET_BITS(instruction, 30, 25) << 5) \
            | (GET_BITS(instruction, 24, 21) << 1);
    decoded_instruction->rd = GET_BITS(instruction, 11, 7);
    decoded_instruction->funct = FUNCT_ADD;
}

void decode_i_type(instruction_t instruction, instruction_s *decoded_instruction) {
    decoded_instruction->imm = (REPLICATE_BIT(GET_BIT(instruction, 31), 21) << 11) \
            | GET_BITS(instruction, 30, 20);
    decoded_instruction->rd = GET_BITS(instruction, 11, 7);
    decoded_instruction->rs1 = GET_BITS(instruction, 19, 15);
    decoded_instruction->funct3 = GET_BITS(instruction, 14, 12);
}

int decode_i_type_int_imm(instruction_s *decoded_instruction) {
    switch (decoded_instruction->funct3) {
        case 0:
            decoded_instruction->funct = FUNCT_ADD;
            break;
        case 1: 
            decoded_instruction->funct = FUNCT_SLL;
            break;
        case 2: 
            decoded_instruction->funct = FUNCT_SLT;
            break;
        case 3: 
            decoded_instruction->funct = FUNCT_SLTU;
            break;
        case 4: 
            decoded_instruction->funct = FUNCT_XOR;
            break;
        case 5:
            switch (GET_BITS(decoded_instruction->imm, 11, 5)) {
                case 0:
                    decoded_instruction->funct = FUNCT_SRL;
                    break;
                case 32: 
                    decoded_instruction->funct = FUNCT_SRA;
                    break;
                default:
                    return IDECODE_ERROR;
            }
            decoded_instruction->imm = GET_BITS(decoded_instruction->imm,4,0);
            break;
        case 6:
            decoded_instruction->funct = FUNCT_OR;
            break;
        case 7: 
            decoded_instruction->funct = FUNCT_AND;
            break;
        default:
            return IDECODE_ERROR;
    }
    return SIM_OK;
}

int decode_i_type_load(instruction_s *decoded_instruction) {
    switch (decoded_instruction->funct3) {
        case 0:
            decoded_instruction->funct = FUNCT_MEM_BYTE;
            break;
        case 1: 
            decoded_instruction->funct = FUNCT_MEM_HWORD;
            break;
        case 2: 
            decoded_instruction->funct = FUNCT_MEM_WORD;
            break;
        case 4:
            decoded_instruction->funct = FUNCT_MEM_BYTEU;
            break;
        case 5:
            decoded_instruction->funct = FUNCT_MEM_HWORDU;
            break;
        default:
            return IDECODE_ERROR;
    }
    return SIM_OK;
}

int decode_r_type(instruction_t instruction, instruction_s *decoded_instruction) {
    decoded_instruction->rs1 = GET_BITS(instruction, 19, 15);
    decoded_instruction->rs2 = GET_BITS(instruction, 24, 20);
    decoded_instruction->rd = GET_BITS(instruction, 11, 7);
    decoded_instruction->funct7 = GET_BITS(instruction, 31, 25);
    decoded_instruction->funct3 = GET_BITS(instruction, 14, 12);
    switch ((decoded_instruction->funct7 << FUNCT3_WIDTH) | decoded_instruction->funct3) {
        case (0 << FUNCT3_WIDTH) | 0:
            decoded_instruction->funct = FUNCT_ADD;
            break;
        case (32 << FUNCT3_WIDTH) | 0:
            decoded_instruction->funct = FUNCT_SUB;
            break;
        case (0 << FUNCT3_WIDTH) | 1:
            decoded_instruction->funct = FUNCT_SLL;
            break;
        case (0 << FUNCT3_WIDTH) | 2:
            decoded_instruction->funct = FUNCT_SLT;
            break;
        case (0 << FUNCT3_WIDTH) | 3:
            decoded_instruction->funct = FUNCT_SLTU;
            break;
        case (0 << FUNCT3_WIDTH) | 4:
            decoded_instruction->funct = FUNCT_XOR;
            break;
        case (0 << FUNCT3_WIDTH) | 5:
            decoded_instruction->funct = FUNCT_SRL;
            break;
        case (32 << FUNCT3_WIDTH) | 5:
            decoded_instruction->funct = FUNCT_SRA;
            break;
        case (0 << FUNCT3_WIDTH) | 6:
            decoded_instruction->funct = FUNCT_OR;
            break;
        case (0 << FUNCT3_WIDTH) | 7:
            decoded_instruction->funct = FUNCT_AND;
        default:
            return IDECODE_ERROR;
    }
    return SIM_OK;
}

int decode_b_type(instruction_t instruction, instruction_s *decoded_instruction) {
    decoded_instruction->imm = (REPLICATE_BIT(GET_BIT(instruction, 31), 20) << 12) \
            | (GET_BIT(instruction, 7) << 11) \
            | (GET_BITS(instruction, 30, 25) << 5) \
            | (GET_BITS(instruction, 11, 8) << 1);
    decoded_instruction->rs1 = GET_BITS(instruction, 19, 15);
    decoded_instruction->rs2 = GET_BITS(instruction, 24, 20);
    decoded_instruction->funct3 = GET_BITS(instruction, 14, 12);
    switch (decoded_instruction->funct3) {
        case 0:
            decoded_instruction->funct = FUNCT_EQ;
            break;
        case 1:
            decoded_instruction->funct = FUNCT_NEQ;
            break;
        case 4:
            decoded_instruction->funct = FUNCT_LT;
            break;
        case 5: 
            decoded_instruction->funct = FUNCT_GTE;
            break;
        case 6: 
            decoded_instruction->funct = FUNCT_LTU;
            break;
        case 7: 
            decoded_instruction->funct = FUNCT_GTEU;
            break;
        default:
            return IDECODE_ERROR;
    }
    return SIM_OK;
}

int decode_s_type(instruction_t instruction, instruction_s *decoded_instruction) {
    decoded_instruction->imm = (REPLICATE_BIT(GET_BIT(instruction, 31), 21) << 11) \
            | (GET_BITS(instruction, 30, 25) << 5) \
            | GET_BITS(instruction, 11, 7);
    decoded_instruction->rs1 = GET_BITS(instruction, 19, 15);
    decoded_instruction->rs2 = GET_BITS(instruction, 24, 20);
    decoded_instruction->funct3 = GET_BITS(instruction, 14, 12);
    switch (decoded_instruction->funct3) {
        case 0:
            decoded_instruction->funct = FUNCT_MEM_BYTE;
            break;
        case 1:
            decoded_instruction->funct = FUNCT_MEM_HWORD;
            break;
        case 2:
            decoded_instruction->funct = FUNCT_MEM_WORD;
        default:
            return IDECODE_ERROR;
    }
    return SIM_OK;
}

int decode(instruction_t instruction, instruction_s *decoded_instruction) {
    printf("> decode\n");
    int opcode = GET_BITS(instruction,6,0);
    decoded_instruction->instruction = instruction;
    decoded_instruction->imm = 0;
    decoded_instruction->inst_type = 0;
    decoded_instruction->rd = 0;
    decoded_instruction->rs1 = 0;
    decoded_instruction->rs2 = 0;
    decoded_instruction->funct = FUNCT_UNKNOWN;
    decoded_instruction->funct3 = 0;
    decoded_instruction->funct7 = 0;
    printf("decode: opcode = 0x%X\n", opcode);
    switch (opcode) {
        case OPCODE_LUI:
            decoded_instruction->inst_type = INST_TYPE_IMM;
            decode_u_type(instruction,decoded_instruction);
            break;
        case OPCODE_JAL:
            decoded_instruction->inst_type = INST_TYPE_JAL;
            decode_j_type(instruction,decoded_instruction);
            break;
        case OPCODE_JALR:
            decoded_instruction->inst_type = INST_TYPE_JALR;
            decode_i_type(instruction,decoded_instruction);
            break;
        case OPCODE_AUIPC:
            decoded_instruction->inst_type = INST_TYPE_AUIPC;
            decode_u_type(instruction,decoded_instruction);
            break;
        case OPCODE_INT_IMM:
            decoded_instruction->inst_type = INST_TYPE_INT_IMM;
            decode_i_type(instruction,decoded_instruction);
            decode_i_type_int_imm(decoded_instruction);
            break;
        case OPCODE_INT_REG:
            decoded_instruction->inst_type = INST_TYPE_INT_REG;
            decode_r_type(instruction,decoded_instruction);
            break;
        case OPCODE_BRANCH:
            decoded_instruction->inst_type = INST_TYPE_BRANCH;
            decode_b_type(instruction,decoded_instruction);
            break;
        case OPCODE_STORE:
            decoded_instruction->inst_type = INST_TYPE_STORE;
            decode_s_type(instruction,decoded_instruction);
            break;
        case OPCODE_LOAD:
            decoded_instruction->inst_type = INST_TYPE_LOAD;
            decode_i_type(instruction,decoded_instruction);
            decode_i_type_load(decoded_instruction);
            break;
        case OPCODE_FENCE:
            decoded_instruction->inst_type = INST_TYPE_FENCE;
            break;
        default:
            return IDECODE_ERROR;
    }
    char buf[1024];
    get_instruction_s_string(*decoded_instruction,buf);
    printf("%s\n",buf);
    return SIM_OK;
}

void get_instruction_s_string(instruction_s decoded_instruction, char *buffer) {
    const char *format = "instruction_s:\n"
        "  instruction = 0x%08X\n"
        "  imm = 0x%X\n"
        "  inst_type = %s\n"
        "  rd = %d\n"
        "  rs1 = %d\n"
        "  rs2 = %d\n"
        "  funct = %s";
    sprintf(buffer, format, decoded_instruction.instruction, \
            decoded_instruction.imm, \
            inst_type_e_string[decoded_instruction.inst_type], \
            decoded_instruction.rd, \
            decoded_instruction.rs1, \
            decoded_instruction.rs2, \
            funct_e_string[decoded_instruction.funct]);
}
