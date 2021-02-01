
i=0; for f in *.S; do sed "/riscv_test.h/ i #define INSTRUCTION_ID $i" $f -i; ((i++)); done
i=0; for f in *.S; do sed "/INSTRUCTION_ID/ a #define TEST_NAME $(basename ${f%.*})" $f -i; ((i++)); done
i=0; for f in *.S; do sed "/TEST_NAME/ a #define TEST_NAME_RET $(basename ${f%.*})_ret" $f -i; ((i++)); done
i=0; for f in *.S; do sed "s/stvec_handler/stvec_handler_$i/" $f -i; ((i++)); done | grep stve
i=0; for f in *.S; do sed "s/mtvec_handler/mtvec_handler_$i/" $f -i; ((i++)); done | grep stve

