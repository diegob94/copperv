#include <stdio.h>

int main(){
    printf("unsiged long = %lu\n",0x80000000);
    printf("expected unsiged long = 2147483648\n");
    printf("\n");
    printf("unsiged long = %llu\n",0x8000000000000000);
    printf("expected unsiged long long = 9223372036854775808\n");
    printf("\n");
    unsigned long long result1 = (100000000ULL * 500);
    printf("result1 = %llu\n",result1);
    printf("expected result1 = 50000000000\n");
    printf("\n");
    long result = (100000000LL * 500) / 3390230;
    printf("result = %ld\n",result);
    printf("expected result = 14748\n");
    return 0;
}
