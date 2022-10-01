#include <stdio.h>
#include "riscv_test.h"

unsigned int volatile * const TIMER_COUNTER = TC_ADDR;

unsigned int get_timer_value(void) {
    unsigned int num = *TIMER_COUNTER;
    return num;
}

int main(){
    printf("timer value 1: %d\n",get_timer_value());
    printf("timer value 2: %d\n",get_timer_value());
    return 0;
}
