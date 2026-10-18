// Test driver for outer, convolve and weirdMul. DO NOT EDIT.
// It times each function, then checks every element against a plain loop.
// ./optim.out nocheck skips the checks, so perf stat counts (almost) only the three functions.

#include <chrono>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <string>
#include "matrix.hpp"

#define epsilon 0.00001

#define OUT_N 63      // outer: two OUT_N x OUT_N matrices -> (OUT_N^2) x (OUT_N^2) result
// The sizes are deliberately not multiples of 2, 4 or 8: SIMD code must handle the leftovers.
#define CONV_N 511    // convolve: CONV_N x CONV_N input
#define CONV_K 33     // convolve: CONV_K x CONV_K kernel (odd)
#define WM_N 401      // weirdMul: two WM_N x WM_N matrices

matrix* random_matrix(uint64_t r, uint64_t c) {
    matrix* m = new matrix(r, c);
    for (uint64_t i = 0; i < r; i++)
        for (uint64_t j = 0; j < c; j++)
            *(m->element(i, j)) = (rand() % 100) / 100.0;
    return m;
}

// Prints a FAIL line for the first wrong element and returns false.
bool same(double got, double want, const char* what, uint64_t i, uint64_t j) {
    if (fabs(got - want) > epsilon) {
        std::cout << what << " FAIL at (" << i << ", " << j << "): expected " << want << " got " << got << "\n";
        return false;
    }
    return true;
}

int main(int argc, char** argv) {
    srand(42);
    bool all_ok = true;
    bool check = !(argc > 1 && std::string(argv[1]) == "nocheck");

    // ---------------- outer ----------------
    matrix* A = random_matrix(OUT_N, OUT_N);
    matrix* B = random_matrix(OUT_N, OUT_N);
    auto start = std::chrono::steady_clock::now();
    matrix* At = outer(A, B);
    auto end = std::chrono::steady_clock::now();
    std::chrono::duration<double, std::milli> duration = end - start;
    bool ok = true;
    for (uint64_t i = 0; check && ok && i < OUT_N; i++)
        for (uint64_t j = 0; ok && j < OUT_N; j++)
            for (uint64_t p = 0; ok && p < OUT_N; p++)
                for (uint64_t q = 0; ok && q < OUT_N; q++)
                    ok = same(*(At->element(i * OUT_N + p, j * OUT_N + q)), (*(A->element(i, j))) * (*(B->element(p, q))),
                              "outer", i * OUT_N + p, j * OUT_N + q);
    std::cout << "Outer Product Time: " << duration.count() << " ms" << (ok ? "" : " (wrong result)") << "\n";
    all_ok = all_ok && ok;

    // ---------------- convolve ----------------
    const int h = (CONV_K - 1) / 2;
    matrix* nA = random_matrix(CONV_N, CONV_N);
    matrix* nC = random_matrix(CONV_K, CONV_K);
    start = std::chrono::steady_clock::now();
    matrix* D = convolve(nA, nC);
    end = std::chrono::steady_clock::now();
    duration = end - start;
    ok = true;
    for (int i = 0; check && ok && i < CONV_N; i++) {
        for (int j = 0; ok && j < CONV_N; j++) {
            double sum = 0.0;
            if (i >= h && i < CONV_N - h && j >= h && j < CONV_N - h)   // border stays 0
                for (int k = -h; k <= h; k++)
                    for (int l = -h; l <= h; l++)
                        sum += (*(nA->element(i + k, j + l))) * (*(nC->element(k + h, l + h)));
            ok = same(*(D->element(i, j)), sum, "convolve", i, j);
        }
    }
    std::cout << "Convolution Time: " << duration.count() << " ms" << (ok ? "" : " (wrong result)") << "\n";
    all_ok = all_ok && ok;

    // ---------------- weirdMul ----------------
    matrix* E1 = random_matrix(WM_N, WM_N);
    matrix* E2 = random_matrix(WM_N, WM_N);
    start = std::chrono::steady_clock::now();
    matrix* E = weirdMul(E1, E2);
    end = std::chrono::steady_clock::now();
    duration = end - start;
    ok = true;
    for (uint64_t i = 0; check && ok && i < WM_N; i++) {
        for (uint64_t j = 0; ok && j < WM_N; j++) {
            double val = 0;
            for (uint64_t k = 0; k < WM_N; k++) {
                if (*(E1->element(i, k)) > 0.5)
                    val += (*(E1->element(i, k))) * (*(E2->element(k, j)));
                else
                    val -= (1 - *(E1->element(i, k))) * (*(E2->element(k, j)));
            }
            ok = same(*(E->element(i, j)), val, "weirdMul", i, j);
        }
    }
    std::cout << "Weird Multiplication Time: " << duration.count() << " ms" << (ok ? "" : " (wrong result)") << "\n";
    all_ok = all_ok && ok;

    if (!check) {
        std::cout << "results not checked (nocheck)\n";
        return 0;
    }
    std::cout << (all_ok ? "PASS: all three results match\n" : "FAIL: at least one result is wrong\n");
    return all_ok ? 0 : 1;
}
