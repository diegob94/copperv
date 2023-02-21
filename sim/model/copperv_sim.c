#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define SIM_OK 0
#define IDECODE_ERROR 1
#define EXECUTE_ERROR 2

#define RETURN_IF_ERROR(x) if ((x) != SIM_OK) return (x);
#define REPLICATE_BIT(x, n) ((x) ? ((1 << (n)) - 1) : 0)
#define GET_BITS(x, j, i) (((x) >> (i)) & REPLICATE_BIT(1, ((j)-(i))+1))
#define GET_BIT(x, n) (((x) >> (n)) & 1)
#define GENERATE_ENUM(ENUM) ENUM,
#define GENERATE_STRING(STRING) #STRING,
#define PRINTVAR(x) printf("debug: "#x" = 0x%X\n",(x))

#define OPCODE_LOAD        ((0x00<<2) | 0b11)
#define OPCODE_FENCE       ((0x03<<2) | 0b11)
#define OPCODE_INT_IMM     ((0x04<<2) | 0b11)
#define OPCODE_AUIPC       ((0x05<<2) | 0b11)
#define OPCODE_STORE       ((0x08<<2) | 0b11)
#define OPCODE_INT_REG     ((0x0C<<2) | 0b11)
#define OPCODE_LUI         ((0x0D<<2) | 0b11)
#define OPCODE_BRANCH      ((0x18<<2) | 0b11)
#define OPCODE_JALR        ((0x19<<2) | 0b11)
#define OPCODE_JAL         ((0x1B<<2) | 0b11)

#define FOREACH_INST_TYPE(FUNC) \
        FUNC(INST_TYPE_IMM) \
        FUNC(INST_TYPE_INT_IMM) \
        FUNC(INST_TYPE_INT_REG) \
        FUNC(INST_TYPE_BRANCH) \
        FUNC(INST_TYPE_STORE) \
        FUNC(INST_TYPE_JAL) \
        FUNC(INST_TYPE_AUIPC) \
        FUNC(INST_TYPE_JALR) \
        FUNC(INST_TYPE_LOAD) \
        FUNC(INST_TYPE_FENCE) \

typedef enum {
    FOREACH_INST_TYPE(GENERATE_ENUM)
} inst_type_e;

static const char *inst_type_e_string[] = {
    FOREACH_INST_TYPE(GENERATE_STRING)
};

#define FOREACH_FUNCT(FUNC) \
        FUNC(FUNCT_ADD) \
        FUNC(FUNCT_SUB) \
        FUNC(FUNCT_AND) \
        FUNC(FUNCT_EQ) \
        FUNC(FUNCT_NEQ) \
        FUNC(FUNCT_LT) \
        FUNC(FUNCT_GTE) \
        FUNC(FUNCT_LTU) \
        FUNC(FUNCT_GTEU) \
        FUNC(FUNCT_MEM_BYTE) \
        FUNC(FUNCT_MEM_HWORD) \
        FUNC(FUNCT_MEM_WORD) \
        FUNC(FUNCT_MEM_BYTEU) \
        FUNC(FUNCT_MEM_HWORDU) \
        FUNC(FUNCT_JAL) \
        FUNC(FUNCT_SLL) \
        FUNC(FUNCT_SLT) \
        FUNC(FUNCT_SLTU) \
        FUNC(FUNCT_XOR) \
        FUNC(FUNCT_SRL) \
        FUNC(FUNCT_SRA) \
        FUNC(FUNCT_OR) \

typedef enum {
    FOREACH_FUNCT(GENERATE_ENUM)
} funct_e;

static const char *funct_e_string[] = {
    FOREACH_FUNCT(GENERATE_STRING)
};

#define FUNCT3_WIDTH       3
#define FUNCT7_WIDTH       7

const char * get_status_string(int status) {
    switch (status) {
        case SIM_OK: return "SIM_OK";
        case IDECODE_ERROR: return "IDECODE_ERROR";
        case EXECUTE_ERROR: return "EXECUTE_ERROR";
    }
    return "UNKNOWN_STATUS";
}

typedef uint32_t instruction_t;

typedef struct {
  uint8_t memory[4096];
  uint32_t regfile[32];
  uint32_t program_counter;
} cpu_state_s;

typedef struct {
    instruction_t instruction;
    int imm; 
    inst_type_e inst_type; 
    int rd; 
    int rs1; 
    int rs2; 
    funct_e funct;
    int funct3;
    int funct7;
} instruction_s;

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

size_t get_memory_length(cpu_state_s *state){
    return sizeof(state->memory);
}

size_t get_regfile_length(cpu_state_s *state){
    return sizeof(state->regfile)/sizeof(state->regfile[0]);
}

void reset_state(cpu_state_s *state) {
    memset(state->memory, 0, sizeof(state->memory));
    memset(state->regfile, 0, sizeof(state->regfile));
    state->program_counter = 0;
}

void decode_u_type(instruction_t instruction, instruction_s *decoded_instruction) {
    decoded_instruction->imm = GET_BITS(instruction,31,12) << 12;
    decoded_instruction->rd = GET_BITS(instruction,11,7);
}

void decode_j_type(instruction_t instruction, instruction_s *decoded_instruction) {
    decoded_instruction->imm = (REPLICATE_BIT(GET_BIT(instruction, 31), 12) << 20) \
            | (GET_BITS(instruction, 19, 12) << 12) \
            | (GET_BIT(instruction, 20) << 11) \
            | (GET_BITS(instruction, 30, 25) << 5) \
            | (GET_BITS(instruction, 24, 21) << 1);
    decoded_instruction->rd = GET_BITS(instruction, 11, 7);
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
    decoded_instruction->funct = 0;
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

typedef struct {
    int data;
    int address;
} mem_buffer_s;

int fetch(uint32_t program_counter, const unsigned char *imemory, instruction_t *instruction) {
    printf("> fetch\n");
    *instruction = (imemory[program_counter+3]<<24) \
        | (imemory[program_counter+2]<<16) \
        | (imemory[program_counter+1]<<8) \
        | imemory[program_counter];
    printf("fetch: program_counter = %d -> 0x%08X\n",program_counter,*instruction);
    return SIM_OK;
}

void regfile_write(uint32_t *regfile, int rd, int value) {
    printf("regfile_write: register = %d data = 0x%X\n",rd,value);
    if (rd != 0) {
        regfile[rd] = value;
    }
}

int execute(instruction_s decoded_instruction, uint32_t *regfile, uint32_t *program_counter, mem_buffer_s *read_buffer, mem_buffer_s *write_buffer) {
    printf("> execute\n");
    int alu_res;
    switch (decoded_instruction.inst_type) {
        case INST_TYPE_IMM:
            *program_counter = *program_counter + 4;
            return EXECUTE_ERROR;
            break;
        case INST_TYPE_INT_IMM:
            *program_counter = *program_counter + 4;
            return EXECUTE_ERROR;
            break;
        case INST_TYPE_INT_REG:
            *program_counter = *program_counter + 4;
            return EXECUTE_ERROR;
            break;
        case INST_TYPE_BRANCH:
            *program_counter = *program_counter + 4;
            return EXECUTE_ERROR;
            break;
        case INST_TYPE_STORE:
            *program_counter = *program_counter + 4;
            return EXECUTE_ERROR;
            break;
        case INST_TYPE_JAL:
            alu_res = *program_counter + 4;
            *program_counter = decoded_instruction.imm;
            regfile_write(regfile,decoded_instruction.rd,alu_res);
            break;
        case INST_TYPE_AUIPC:
            *program_counter = *program_counter + 4;
            return EXECUTE_ERROR;
            break;
        case INST_TYPE_JALR:
            *program_counter = *program_counter + 4;
            return EXECUTE_ERROR;
            break;
        case INST_TYPE_LOAD:
            *program_counter = *program_counter + 4;
            return EXECUTE_ERROR;
            break;
        case INST_TYPE_FENCE:
            *program_counter = *program_counter + 4;
            return EXECUTE_ERROR;
            break;
    }
    return SIM_OK;
}

int commit(instruction_s decoded_instruction, unsigned char * memory, mem_buffer_s *read_buffer, mem_buffer_s *write_buffer) {
}

int sim_step(const char *imemory, cpu_state_s *state) {
    mem_buffer_s read_buffer;
    mem_buffer_s write_buffer;
    instruction_t instruction;
    instruction_s decoded_instruction;
    int status = SIM_OK;
    // Processor stages:
    fetch(state->program_counter, imemory, &instruction);
    status = decode(instruction, &decoded_instruction);
    RETURN_IF_ERROR(status);
    status = execute(decoded_instruction, state->regfile, &state->program_counter, &read_buffer, &write_buffer);
    RETURN_IF_ERROR(status);
    commit(decoded_instruction, state->memory, &read_buffer, &write_buffer);
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
    printf("last status = %s\n", get_status_string(status));
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
    buffer = (char*) malloc (sizeof(char)*lSize);
    if (buffer == NULL) {
        printf("Memory error\n");
        exit(1);
    }
    result = fread(buffer,4,lSize/4,ptr);
    if(result != lSize/4) {
        printf("File reading error (result = %ld, lSize = %ld)\n",result,lSize);
        exit(1);
    }
    fclose(ptr);
    sim_main(buffer,lSize/4);
    free (buffer);    
    return 0;
}

