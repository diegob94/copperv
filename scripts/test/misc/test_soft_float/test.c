void _start(){
    volatile int a = 10;
    volatile int b = 5;
    volatile int c = a/b; // Implemented as a call to '__divdi3'
}
