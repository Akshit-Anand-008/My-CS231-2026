#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <string>

// Edit only between the YOUR ... BELOW / ABOVE markers. Everything else is DO NOT EDIT.

#define N 131072     // array length (512 KB: too long a pattern for the branch predictor to memorise)
#define REPS 6000    // how many times the whole array is processed

// the naive result, so a "yours" run can be checked without running the naive part
#define EXPECTED_ACCUM 1940869712

volatile int accum = 0;
volatile int arr[N];

int main(int argc, char** argv) {
    srand(42); // seeds the randomness
    // fill arr with random values in [0, N)
    for (int i = 0; i < N; i++) {
        arr[i] = rand() % N;
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
        for (int i = 0; i < REPS; i++) {
            for (int j = 0; j < N; j++) {
                if (arr[j] > N / 2) {
                    accum += i * arr[j];
                }
                else {
                    accum -= i * arr[j];
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

    /* YOU MAY USE THE BELOW SPACE TO SETUP VARIABLES */
    // Declare and initialise variables here. Do not compute the answer here.

    /* YOU MAY USE THE ABOVE SPACE TO SETUP VARIABLES */

    for (int i = 0; i < REPS; i++) {
        for (int j = 0; j < N; j++) {
            /* YOUR COMPUTATIONS SHOULD BE DONE IN THE SPACE BELOW */

            /* YOUR COMPUTATIONS SHOULD BE DONE IN THE SPACE ABOVE */
        }
    }

    /* YOU MAY USE THE BELOW SPACE TO FINISH UP */
    // For example, copy a local result into accum.

    /* YOU MAY USE THE ABOVE SPACE TO FINISH UP */

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
