
void add1(const int x, int *y) {
    (*y) = x + 1;
}

typedef struct ABC_s {
  char A;
  int B;
  int C;
} ABC;

void add1struct(const ABC *inp, ABC *result) {
    result->A = inp->A + 1;
    result->B = inp->B + 1;
    result->C = inp->C + 1;
}

