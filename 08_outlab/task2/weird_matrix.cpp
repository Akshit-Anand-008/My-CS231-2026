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
    // Compute the same accum as the naive version, faster. Any preparation you do here is timed.

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
