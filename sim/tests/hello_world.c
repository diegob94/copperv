#include <stdio.h>
#include "riscv_test.h"

int volatile * const TEST_RESULT = T_ADDR;
int volatile * const SIM_UART_TX_BUF = 0x34 << 2;

void _putc(char c){
    *SIM_UART_TX_BUF = c;
}

int main(){
    _putc('H');
    _putc('e');
    _putc('l');
    _putc('l');
    _putc('o');
    *TEST_RESULT = T_PASS;
}
