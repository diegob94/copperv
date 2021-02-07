#include <stdint.h>

volatile uint64_t tohost __attribute__((section(".syscall"))) = 0x11;
volatile uint64_t fromhost __attribute__((section(".syscall"))) = 0x22;

