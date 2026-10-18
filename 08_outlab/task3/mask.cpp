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
    // Compute layer2OutSIMD with SSE2 intrinsics (__m128d, _mm_*_pd). Use layer1OutsSIMD for layer 1.

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
