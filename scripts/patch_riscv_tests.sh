
i=0; for f in *.S; do sed "/RVTEST_CODE_BEGIN/ a #define INSTRUCTION_ID $i" $f -i; ((i++)); done
i=0; for f in *.S; do sed "s/stvec_handler/stvec_handler_$i/" $f -i; ((i++)); done | grep stve
i=0; for f in *.S; do sed "s/mtvec_handler/mtvec_handler_$i/" $f -i; ((i++)); done | grep stve

