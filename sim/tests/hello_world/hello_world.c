#include <stdio.h>
#include "riscv_test.h"
#include "copperv.h"

int volatile * const TEST_RESULT = T_ADDR;
int volatile * const SIM_OUT = O_ADDR;

void _putc(char c){
    *SIM_OUT = c;
}
void print(char* c){
    while(*c) _putc(*(c++));
}

int main(){
    print("Hello World\n");
    *TEST_RESULT = T_PASS;
}
