
#include <stdint.h>

#define SIM_OK        0
#define IDECODE_ERROR 1
#define EXECUTE_ERROR 2
#define ALU_ERROR     3

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
        FUNC(FUNCT_UNKNOWN) \

typedef enum {
    FOREACH_FUNCT(GENERATE_ENUM)
} funct_e;

static const char *funct_e_string[] = {
    FOREACH_FUNCT(GENERATE_STRING)
};

#define FUNCT3_WIDTH       3
#define FUNCT7_WIDTH       7

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

typedef struct {
    int data;
    int address;
} mem_buffer_s;

void get_instruction_s_string(instruction_s, char *);
int decode(instruction_t, instruction_s *);

