#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <immintrin.h>
#include <iostream>
#include <string>
#include "vector.hpp"

/*
Layer 1:
n cells, each has to compute y[i] = sum_j[max(0, w[i,j] * x[j])] where x[j] is the jth element of the input,
                                                                     w[i,j] is the jth weight of the ith cell.

Layer 2:
1 cell, has to compute out = sum_[i=1; i < NUM_CELL; i++](max(y[i], (y[i-1] + 1) * y[i]))

You may assume INPUT_DIM and NUM_CELL are multiples of 8.
Edit only between the YOUR CODE BELOW / ABOVE markers. Everything else is DO NOT EDIT.
*/

#define NUM_CELL 2048
#define INPUT_DIM 8192

// the naive result, so a "yours" run can be checked without running the naive part
#define EXPECTED_OUTPUT 4106230095331.0

vector** layer1CellWeights;
vector layer1Outs(NUM_CELL);
vector layer1OutsSIMD(NUM_CELL + 8); // why?
vector input(INPUT_DIM);

int main(int argc, char** argv) {
    srand(42);
    for (int i = 0; i < INPUT_DIM; i++) {
        *(input.element(i)) = rand() % 10 - rand() % 10;
    }
    layer1CellWeights = new vector*[NUM_CELL];
    for (int i = 0; i < NUM_CELL; i++) {
        layer1CellWeights[i] = new vector(INPUT_DIM);
        for (int j = 0; j < INPUT_DIM; j++) {
            *(layer1CellWeights[i]->element(j)) = rand() % 10 - rand() % 10;
        }
    }

    // Run modes. No argument: naive part, then your part, then the check.
    // "naive" or "yours": only that part. Both modes do the same set-up, so with perf stat their
    // counts differ only by the part that ran (yours is still checked against the known answer).
    std::string mode = (argc > 1) ? argv[1] : "both";
    bool run_naive = (mode != "yours");
    bool run_yours = (mode != "naive");

    // ---------------- naive version (DO NOT EDIT) ----------------
    long naive_ms = 0;
    double layer2Out = EXPECTED_OUTPUT;
    if (run_naive) {
        auto preAdd = std::chrono::steady_clock::now();
        for (int i = 0; i < NUM_CELL; i++) {
            *(layer1Outs.element(i)) = 0;
            for (int j = 0; j < INPUT_DIM; j++) {
                *(layer1Outs.element(i)) += std::max(0.0, (*(layer1CellWeights[i]->element(j))) * (*(input.element(j))));
            }
        }
        layer2Out = 0;
        for (int i = 1; i < NUM_CELL; i++) {
            double val1 = *(layer1Outs.element(i));
            double val2 = (*(layer1Outs.element(i - 1)) + 1) * (*(layer1Outs.element(i)));
            layer2Out += std::max(val1, val2);
        }
        auto postAdd = std::chrono::steady_clock::now();
        naive_ms = std::chrono::duration_cast<std::chrono::milliseconds>(postAdd - preAdd).count();
        std::cout << "naive: output = " << layer2Out << " time_ms = " << naive_ms << std::endl;
    }
    if (!run_yours) return 0;

    // ---------------- your SIMD version ----------------
    auto preAdd = std::chrono::steady_clock::now();
    double layer2OutSIMD = 0;

    /* YOUR CODE BELOW */
    // Width W = doubles per register: SSE2 __m128d holds 2. The optional AVX / AVX-512 paths
    // (make mask SIMD=avx / SIMD=avx512) are the same code with 4 / 8 lanes.
#if defined(__AVX512F__)
    #define W 8
    typedef __m512d vd;
    #define LOAD _mm512_loadu_pd
    #define ADD _mm512_add_pd
    #define MUL _mm512_mul_pd
    #define MAX _mm512_max_pd
    #define ZERO _mm512_setzero_pd
    #define SET1 _mm512_set1_pd
    #define STORE _mm512_storeu_pd
#elif defined(__AVX__)
    #define W 4
    typedef __m256d vd;
    #define LOAD _mm256_loadu_pd
    #define ADD _mm256_add_pd
    #define MUL _mm256_mul_pd
    #define MAX _mm256_max_pd
    #define ZERO _mm256_setzero_pd
    #define SET1 _mm256_set1_pd
    #define STORE _mm256_storeu_pd
#else
    #define W 2
    typedef __m128d vd;
    #define LOAD _mm_loadu_pd
    #define ADD _mm_add_pd
    #define MUL _mm_mul_pd
    #define MAX _mm_max_pd
    #define ZERO _mm_setzero_pd
    #define SET1 _mm_set1_pd
    #define STORE _mm_storeu_pd
#endif

    // Layer 1. Get plain pointers once: at -O0 every element() call is a real function call.
    double* x = input.element(0);
    double* y = layer1OutsSIMD.element(0);
    for (int i = 0; i < NUM_CELL; i++) {
        double* w = layer1CellWeights[i]->element(0);
        vd acc = ZERO();
        // INPUT_DIM is a multiple of 8, so there are no leftovers here
        for (int j = 0; j < INPUT_DIM; j += W) {
            vd p = MUL(LOAD(&w[j]), LOAD(&x[j]));   // W products at once
            acc = ADD(acc, MAX(p, ZERO()));          // max(0, p) lane by lane
        }
        // add the W lanes together
        double lanes[W];
        STORE(lanes, acc);
        double sum = 0;
        for (int l = 0; l < W; l++) sum += lanes[l];
        y[i] = sum;
    }

    // Layer 2: out += max(y[i], (y[i-1] + 1) * y[i]) for i = 1 .. NUM_CELL-1.
    // Lanes hold i, i+1, ...: load y[i..] and y[i-1..] (an unaligned load one element back).
    vd acc2 = ZERO();
    int i = 1;
    for (; i + W <= NUM_CELL; i += W) {
        vd cur = LOAD(&y[i]);
        vd prev = LOAD(&y[i - 1]);
        acc2 = ADD(acc2, MAX(cur, MUL(ADD(prev, SET1(1.0)), cur)));
    }
    double lanes2[W];
    STORE(lanes2, acc2);
    for (int l = 0; l < W; l++) layer2OutSIMD += lanes2[l];
    // leftovers: NUM_CELL - 1 terms is not a multiple of W
    for (; i < NUM_CELL; i++)
        layer2OutSIMD += std::max(y[i], (y[i - 1] + 1) * y[i]);

    /* YOUR CODE ABOVE */

    auto postAdd = std::chrono::steady_clock::now();
    long yours_ms = std::chrono::duration_cast<std::chrono::milliseconds>(postAdd - preAdd).count();
    std::cout << "yours: output = " << layer2OutSIMD << " time_ms = " << yours_ms << std::endl;

    // ---------------- check (DO NOT EDIT) ----------------
    // Every value here is a whole number well below 2^53, so doubles add them exactly in any order.
    if (layer2OutSIMD == layer2Out) {
        std::cout << "PASS: same result";
        if (run_naive) std::cout << ", speedup = " << (double)naive_ms / (yours_ms ? yours_ms : 1) << "x";
        std::cout << std::endl;
    } else {
        std::cout << "FAIL: output differs from the naive result" << std::endl;
    }
}
