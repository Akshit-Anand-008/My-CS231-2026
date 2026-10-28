#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <string>

// You may change anything between the YOUR CODE BELOW / ABOVE markers, including adding
// helper arrays. Everything else is DO NOT EDIT.

#define N 1000

// the naive result, so a "yours" run can be checked without running the naive part
#define EXPECTED_ACCUM 2085874902

volatile int accum = 0;
volatile int arr[N];
volatile int m1[N][N];
volatile int m2[N][N];

int main(int argc, char** argv) {
    srand(42); // seeds the randomness
    // fill arr and both matrices with random values
    for (int i = 0; i < N; i++) {
        arr[i] = rand() % N;
        for (int j = 0; j < N; j++) {
            m1[i][j] = rand() % 100;
            m2[i][j] = rand() % 100;
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
    int naive_accum = EXPECTED_ACCUM;
    if (run_naive) {
        auto preAdd = std::chrono::steady_clock::now();
        accum = 0;
        for (int i = 0; i < N; i++) {
            for (int j = 0; j < N; j++) {
                if (arr[j] > N / 2) {
                    // add the dot product of column i of m1 (rows picked by arr) and column arr[j] of m2
                    int dotP = 0;
                    for (int k = 0; k < N; k++) {
                        dotP += m1[arr[k]][i] * m2[k][arr[j]];
                    }
                    accum += dotP;
                }
                else {
                    // subtract the dot product of column arr[j] of m1 and column i of m2 (rows picked by arr)
                    int dotP = 0;
                    for (int k = 0; k < N; k++) {
                        dotP += m1[k][arr[j]] * m2[arr[k]][i];
                    }
                    accum -= dotP;
                }
            }
        }
        auto postAdd = std::chrono::steady_clock::now();
        naive_ms = std::chrono::duration_cast<std::chrono::milliseconds>(postAdd - preAdd).count();
        naive_accum = accum;
        std::cout << "naive: accum = " << naive_accum << " time_ms = " << naive_ms << std::endl;
    }
    if (!run_yours) return 0;

    // ---------------- your version ----------------
    auto preAdd = std::chrono::steady_clock::now();
    accum = 0;

    /* YOUR CODE BELOW */
    // Problem 1: the naive inner loop over k walks DOWN columns (m1[..][i], m2[k][..]):
    //   each read is N ints = 4000 bytes from the last one, a new cache line every time (Lab 8, Task 2).
    // Problem 2: the matrices are volatile, so every read really goes to memory.
    // Fix: copy each column we need into a row of a plain (non-volatile) array once, O(N^2) work,
    // so the O(N^3) dot products then walk along rows.
    static int P1[N][N];   // P1[i][k] = m1[arr[k]][i]
    static int T2[N][N];   // T2[c][k] = m2[k][c]     (column c of m2)
    static int T1[N][N];   // T1[c][k] = m1[k][c]     (column c of m1)
    static int P2[N][N];   // P2[i][k] = m2[arr[k]][i]
    static int a[N];
    for (int k = 0; k < N; k++) a[k] = arr[k];
    for (int k = 0; k < N; k++) {
        for (int c = 0; c < N; c++) {
            // reading row a[k] / row k along c is sequential; the writes are strided, but only N^2 of them
            P1[c][k] = m1[a[k]][c];
            P2[c][k] = m2[a[k]][c];
            T1[c][k] = m1[k][c];
            T2[c][k] = m2[k][c];
        }
    }

    int total = 0;
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            int c = a[j];
            int dotP = 0;
            if (c > N / 2) {
                const int* x = P1[i];   // row pointers: at -O0 this saves recomputing i*N+k every step
                const int* y = T2[c];
                for (int k = 0; k < N; k++) dotP += x[k] * y[k];
                total += dotP;
            } else {
                const int* x = T1[c];
                const int* y = P2[i];
                for (int k = 0; k < N; k++) dotP += x[k] * y[k];
                total -= dotP;
            }
        }
    }
    accum = total;

    /* YOUR CODE ABOVE */

    auto postAdd = std::chrono::steady_clock::now();
    long yours_ms = std::chrono::duration_cast<std::chrono::milliseconds>(postAdd - preAdd).count();
    std::cout << "yours: accum = " << accum << " time_ms = " << yours_ms << std::endl;

    // ---------------- check (DO NOT EDIT) ----------------
    if (accum == naive_accum) {
        std::cout << "PASS: same result";
        if (run_naive) std::cout << ", speedup = " << (double)naive_ms / (yours_ms ? yours_ms : 1) << "x";
        std::cout << std::endl;
    } else {
        std::cout << "FAIL: accum differs from the naive result" << std::endl;
    }
}
