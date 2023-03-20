#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include "copperv_sim.h"

size_t get_memory_length(cpu_state_s *state){
    return sizeof(state->memory);
}

size_t get_regfile_length(cpu_state_s *state){
    return sizeof(state->regfile)/sizeof(state->regfile[0]);
}

void reset_state(cpu_state_s *state) {
    memset(state->memory, 0, sizeof(state->memory));
    memset(state->regfile, 0, sizeof(state->regfile));
    state->program_counter = INITIAL_PROGRAM_COUNTER;
}

int fetch(uint32_t program_counter, const unsigned char *imemory, instruction_t *instruction) {
    printf("> fetch\n");
    printf("fetch: program_counter = 0x%08X",program_counter);
    *instruction = (imemory[program_counter+3]<<24) \
        | (imemory[program_counter+2]<<16) \
        | (imemory[program_counter+1]<<8) \
        | imemory[program_counter];
    printf(" -> 0x%08X\n",*instruction);
    return SIM_OK;
}

void regfile_write(uint32_t *regfile, int rd, uint32_t value) {
    printf("regfile_write: register = %d data = 0x%X\n",rd,value);
    if (rd != 0) {
        regfile[rd] = value;
    }
}
void regfile_read(uint32_t *regfile, int rs1, uint32_t *value1, int rs2, uint32_t *value2) {
    char buf1[1024];
    char buf2[1024];
    buf1[0] = '\0';
    buf2[0] = '\0';
    if(value1) {
        *value1 = 0;
        if (rs1 != 0) {
            *value1 = regfile[rs1];
        }
        sprintf(buf1, "regfile_read: register1 = %d data1 = 0x%X",rs1,*value1);
    }
    if(value2) {
        *value2 = 0;
        if (rs2 != 0) {
            *value2 = regfile[rs2];
        }
        sprintf(buf2, " register2 = %d data2 = 0x%X",rs2,*value2);
    }
    printf("%s%s\n",buf1,buf2);
}

void get_alu_s_string(alu_s res, char *buffer) {
    const char *format = "alu_s:\n"
        "  op1 = 0x%08X\n"
        "  op2 = 0x%08X\n"
        "  result = 0x%08X\n"
        "  funct = %s\n"
        "  equal = %d\n"
        "  less_than = %d\n"
        "  less_than_unsigned = %d\n";
    sprintf(buffer, format, res.op1, \
            res.op2, \
            res.result, \
            funct_e_string[res.funct], \
            res.equal, \
            res.less_than, \
            res.less_than_unsigned);
}

int alu(funct_e funct, uint32_t op1, uint32_t op2, alu_s *res) {
    uint32_t shift = GET_BITS(op2,5,0);
    int32_t s_op1 = (int32_t)op1;
    int32_t s_op2 = (int32_t)op2;
    switch (funct) {
        case FUNCT_ADD:
            res->result = op1 + op2;
            break;
        case FUNCT_SUB:
            res->result = op1 - op2;
            break;
        case FUNCT_AND:
            res->result = op1 & op2;
            break;
        case FUNCT_OR:
            res->result = op1 | op2;
            break;
        case FUNCT_XOR:
            res->result = op1 ^ op2;
            break;
        case FUNCT_SLL:
            res->result = op1 << shift;
            break;
        case FUNCT_SRA:
            res->result = s_op1 >> shift;
            break;
        case FUNCT_SRL:
            res->result = op1 >> shift;
            break;
        case FUNCT_SLT:
            res->result = s_op1 < s_op2;
            break;
        case FUNCT_SLTU:
            res->result = op1 < op2;
            break;
        default: return SIM_OK;
    }
    res->op1 = op1;
    res->op2 = op2;
    res->funct = funct;
    res->equal = op1 == op2;
    res->less_than = s_op1 < s_op2;
    res->less_than_unsigned = op1 < op2;
    char buf[1024];
    get_alu_s_string(*res,buf);
    printf("%s",buf);
    return SIM_OK;
}

int execute(instruction_s decoded_instruction, uint32_t *regfile, uint32_t *program_counter, mem_buffer_s *read_buffer, mem_buffer_s *write_buffer) {
    printf("> execute\n");
    alu_s alu_res;
    uint32_t rs1_res = 0;
    uint32_t rs2_res = 0;
    switch (decoded_instruction.inst_type) {
        case INST_TYPE_IMM:
            regfile_write(regfile,decoded_instruction.rd,decoded_instruction.imm);
            *program_counter = *program_counter + 4;
            break;
        case INST_TYPE_INT_IMM:
            regfile_read(regfile,decoded_instruction.rs1,&rs1_res,0,NULL);
            RETURN_IF_ERROR(alu(decoded_instruction.funct,rs1_res,decoded_instruction.imm,&alu_res));
            *program_counter = *program_counter + 4;
            regfile_write(regfile,decoded_instruction.rd,alu_res.result);
            break;
        case INST_TYPE_INT_REG:
            regfile_read(regfile,decoded_instruction.rs1,&rs1_res,decoded_instruction.rs2,&rs2_res);
            RETURN_IF_ERROR(alu(decoded_instruction.funct,rs1_res,rs2_res,&alu_res));
            *program_counter = *program_counter + 4;
            regfile_write(regfile,decoded_instruction.rd,alu_res.result);
            break;
        case INST_TYPE_BRANCH:
            RETURN_IF_ERROR(alu(decoded_instruction.funct,rs1_res,rs2_res,&alu_res));
            int take_branch;
            switch (decoded_instruction.funct) {
                FUNCT_EQ:
                    take_branch = alu_res.equal;
                    break;
                FUNCT_NEQ:
                    take_branch = !alu_res.equal;
                    break;
                FUNCT_LT:
                    take_branch = alu_res.less_than;
                    break;
                FUNCT_GTE:
                    take_branch = !alu_res.less_than;
                    break;
                FUNCT_LTU:
                    take_branch = alu_res.less_than_unsigned;
                    break;
                FUNCT_GTEU:
                    take_branch = !alu_res.less_than_unsigned;
                    break;
                default:
                    take_branch = 0;
                    break;
            }
            *program_counter = *program_counter + 4;
            printf("take_branch = %d\n",take_branch);
            if (take_branch) {
                *program_counter = *program_counter + decoded_instruction.imm;
            }
            break;
        case INST_TYPE_STORE:
            regfile_read(regfile,decoded_instruction.rs1,&rs1_res,decoded_instruction.rs2,&rs2_res);
            *program_counter = *program_counter + 4;
            RETURN_IF_ERROR(alu(FUNCT_ADD,rs1_res,decoded_instruction.imm,&alu_res));
            write_buffer->flag = 1;
            write_buffer->address = alu_res.result;
            switch (decoded_instruction.funct) {
                case FUNCT_MEM_BYTE:
                    write_buffer->data = GET_BITS(rs2_res, 7, 0);
                    write_buffer->mask = 0xFF;
                    break;
                case FUNCT_MEM_HWORD:
                    write_buffer->data = GET_BITS(rs2_res, 15, 0);
                    write_buffer->mask = 0xFFFF;
                    break;
                case FUNCT_MEM_WORD:
                    write_buffer->data = rs2_res;
                    write_buffer->mask = 0xFFFFFFFF;
                    break;
                default:
                    return EXECUTE_ERROR;
            }
            break;
        case INST_TYPE_JAL:
            RETURN_IF_ERROR(alu(decoded_instruction.funct,*program_counter,4,&alu_res));
            *program_counter = *program_counter + decoded_instruction.imm;
            regfile_write(regfile,decoded_instruction.rd,alu_res.result);
            break;
        case INST_TYPE_AUIPC:
            RETURN_IF_ERROR(alu(decoded_instruction.funct,*program_counter,decoded_instruction.imm,&alu_res));
            *program_counter = *program_counter + 4;
            regfile_write(regfile,decoded_instruction.rd,alu_res.result);
            break;
        case INST_TYPE_JALR:
            regfile_read(regfile,decoded_instruction.rs1,&rs1_res,decoded_instruction.rs2,&rs2_res);
            RETURN_IF_ERROR(alu(FUNCT_ADD,*program_counter,4,&alu_res));
            regfile_write(regfile,decoded_instruction.rd,alu_res.result);
            *program_counter = rs1_res + decoded_instruction.imm;
            break;
        case INST_TYPE_LOAD:
            regfile_read(regfile,decoded_instruction.rs1,&rs1_res,decoded_instruction.rs2,&rs2_res);
            *program_counter = *program_counter + 4;
            RETURN_IF_ERROR(alu(FUNCT_ADD,rs1_res,decoded_instruction.imm,&alu_res));
            read_buffer->flag = 1;
            read_buffer->address = alu_res.result;
            break;
        case INST_TYPE_FENCE:
            *program_counter = *program_counter + 4;
            return EXECUTE_ERROR;
            break;
    }
    return SIM_OK;
}

int write_memory(unsigned char * memory, uint32_t address, uint32_t data, uint32_t mask) {
    printf("write_memory: address = 0x%08X data = 0x%08X mask = 0x%08X\n",address,data,mask);
    if (mask == 0)
        return MEMORY_ERROR;
    if (mask & (0xFF << 0)) {
        memory[address + 0] = GET_BITS(data,7,0);
    }
    if (mask & (0xFF << 8)) {
        memory[address + 1] = GET_BITS(data,15,8);
    }
    if (mask & (0xFF << 16)) {
        memory[address + 2] = GET_BITS(data,23,16);
    }
    if (mask & (0xFF << 24)) {
        memory[address + 3] = GET_BITS(data,31,24);
    }
    return SIM_OK;
}

int read_memory(unsigned char * memory, uint32_t address, uint32_t *data) {
    printf("read_memory: address = 0x%08X",address);
    *data = (memory[address + 3] << 24) \
          | (memory[address + 2] << 16) \
          | (memory[address + 1] << 8) \
          | (memory[address + 0] << 0);
    printf(" data = 0x%08X\n",*data);
    return SIM_OK;
}

int commit(instruction_s decoded_instruction, unsigned char * memory, uint32_t *regfile, mem_buffer_s *read_buffer, mem_buffer_s *write_buffer) {
    if (write_buffer->flag) {
        RETURN_IF_ERROR(write_memory(memory,write_buffer->address,write_buffer->data,write_buffer->mask));
    }
    if (read_buffer->flag) {
        RETURN_IF_ERROR(read_memory(memory,read_buffer->address,&read_buffer->data));
        switch (decoded_instruction.funct) {
            case FUNCT_MEM_BYTE:
                read_buffer->data = (int8_t)(read_buffer->data & 0xFF);
                break;
            case FUNCT_MEM_HWORD:
                read_buffer->data = (int8_t)(read_buffer->data & 0xFFFF);
                break;
            case FUNCT_MEM_WORD:
                break;
            case FUNCT_MEM_BYTEU:
                read_buffer->data = read_buffer->data & 0xFF;
                break;
            case FUNCT_MEM_HWORDU:
                read_buffer->data = read_buffer->data & 0xFF;
                break;
            default:
                return EXECUTE_ERROR;
        }
        regfile_write(regfile, decoded_instruction.rd, read_buffer->data);
    }
    return SIM_OK;
}

int sim_step(const unsigned char *imemory, cpu_state_s *state) {
    mem_buffer_s read_buffer;
    mem_buffer_s write_buffer;
    read_buffer.flag = 0;
    write_buffer.flag = 0;
    instruction_t instruction;
    instruction_s decoded_instruction;
    // Processor stages:
    RETURN_IF_ERROR(fetch(state->program_counter, imemory, &instruction));
    RETURN_IF_ERROR(decode(instruction, &decoded_instruction));
    RETURN_IF_ERROR(execute(decoded_instruction, state->regfile, &state->program_counter, &read_buffer, &write_buffer));
    RETURN_IF_ERROR(commit(decoded_instruction, state->memory, state->regfile, &read_buffer, &write_buffer));
    return SIM_OK;
}

void sim_main(const char *buffer, size_t buffer_size) {
    // TODO: regression this:
    // test1
    //PRINTVAR(GET_BITS(12, 3, 2));
    //PRINTVAR(GET_BITS(0x106F, 11, 7));
    //debug: GET_BITS(12, 3, 2) = 0x3
    //debug: GET_BITS(0x106F, 11, 7) = 0x0
    //
    // test2
    //instruction_s:
    //  instruction = 0x0000106F
    //  imm = 0x1000
    //  inst_type = INST_TYPE_JAL
    //  rd = 0
    //  rs1 = 0
    //  rs2 = 0
    //  funct = FUNCT_ADD
    instruction_t instruction;
    cpu_state_s state;
    reset_state(&state);
    int status = SIM_OK;
    while (status == SIM_OK) {
        status = sim_step(buffer,&state);
    }
    printf("last status = %s\n", sim_status_e_string[status]);
}

FILE *ptr;
long lSize;
char * buffer;
size_t result;

int main (int argc, char *argv[]) {
    if (argc - 1 != 1) {
        printf("Usage: copperv <bin_file>\n");
        exit(1);
    }
    ptr = fopen(argv[1],"rb");  // r for read, b for binary
    if (ptr == NULL) {
        printf("File error: %s\n",argv[1]);
        exit(1);
    }
    // obtain file size:
    fseek(ptr , 0 , SEEK_END);
    lSize = ftell(ptr);
    rewind(ptr);
    buffer = (char*) malloc (lSize + INITIAL_PROGRAM_COUNTER);
    if (buffer == NULL) {
        printf("Memory error\n");
        exit(1);
    }
    result = fread(buffer+INITIAL_PROGRAM_COUNTER,4,lSize/4,ptr);
    if(result != lSize/4) {
        printf("File reading error (result = %ld, lSize = %ld)\n",result,lSize);
        exit(1);
    }
    fclose(ptr);
    sim_main(buffer,lSize/4);
    free (buffer);    
    return 0;
}

