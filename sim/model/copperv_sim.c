#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

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
    for(int i = 0; i < lSize / 4; i++){
        printf("%d -> 0x%X\n",i,buffer[i]);
    }
    free (buffer);    
    return 0;
}

