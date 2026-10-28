/*
Reference SIMD versions of outer, convolve and weirdMul. NOT SHIPPED to students.

SSE2 (__m128d, 2 doubles) by default. The same code builds with 4 lanes (make optim SIMD=avx)
or 8 lanes (SIMD=avx512); only the macros below change.
Every function also takes plain row pointers once: at -O0 each element() call is a real call.
*/

#include "matrix.hpp"
#include <cmath>
#include <immintrin.h>

#if defined(__AVX512F__)
    #define W 8
    typedef __m512d vd;
    #define LOAD _mm512_loadu_pd
    #define STORE _mm512_storeu_pd
    #define ADD _mm512_add_pd
    #define MUL _mm512_mul_pd
    #define ZERO _mm512_setzero_pd
    #define SET1 _mm512_set1_pd
#elif defined(__AVX__)
    #define W 4
    typedef __m256d vd;
    #define LOAD _mm256_loadu_pd
    #define STORE _mm256_storeu_pd
    #define ADD _mm256_add_pd
    #define MUL _mm256_mul_pd
    #define ZERO _mm256_setzero_pd
    #define SET1 _mm256_set1_pd
#else
    #define W 2
    typedef __m128d vd;
    #define LOAD _mm_loadu_pd
    #define STORE _mm_storeu_pd
    #define ADD _mm_add_pd
    #define MUL _mm_mul_pd
    #define ZERO _mm_setzero_pd
    #define SET1 _mm_set1_pd
#endif

matrix* outer(matrix *a, matrix *b) {
    auto [r1, c1] = a->size();
    auto [r2, c2] = b->size();
    matrix *res = new matrix(r1 * r2, c1 * c2);
    // res[i*r2 + p][j*c2 + q] = a[i][j] * b[p][q]:
    // for fixed (i, j, p) this is one row of b times the same number -> broadcast it, W at a time.
    for (uint64_t i = 0; i < r1; i++) {
        for (uint64_t j = 0; j < c1; j++) {
            vd s = SET1(*(a->element(i, j)));
            double sa = *(a->element(i, j));
            for (uint64_t p = 0; p < r2; p++) {
                double* src = b->element(p, 0);
                double* dst = res->element(i * r2 + p, j * c2);
                uint64_t q = 0;
                for (; q + W <= c2; q += W)
                    STORE(&dst[q], MUL(s, LOAD(&src[q])));
                for (; q < c2; q++)          // leftovers
                    dst[q] = sa * src[q];
            }
        }
    }
    return res;
}

matrix* convolve(matrix* a, matrix* b) {
    // output matrix dim must be same as a-> dim
    // and a->dim must be greater than b->dim
    auto [r1, c1] = a->size();
    auto [r2, c2] = b->size();
    if (r1 < r2 || c1 < c2) {
        return nullptr; // Dimension mismatch
    }
    if (r2 % 2 == 0 || c2 % 2 == 0) {
        return nullptr; // Kernel dimensions must be odd
    }
    matrix* res = new matrix(r1, c1);
    const int hr = (r2 - 1) / 2, hc = (c2 - 1) / 2;
    const int C1 = c1, C2 = c2;
    // W neighbouring outputs res[i][j .. j+W-1] use the same kernel value b[k][l] with inputs
    // a[i+k-hr][j+l-hc ..] that sit next to each other in a row: one broadcast, one load, W products.
    // Each lane adds its terms in the same k, l order as naive.cpp, so results match exactly.
    for (int i = hr; i < (int)r1 - hr; i++) {
        double* out = res->element(i, 0);
        int j = hc;
        for (; j + W <= (int)c1 - hc; j += W) {
            vd acc = ZERO();
            for (int k = 0; k < (int)r2; k++) {
                double* arow = a->element(i + k - hr, 0) + (j - hc);
                double* brow = b->element(k, 0);
                for (int l = 0; l < C2; l++)
                    acc = ADD(acc, MUL(LOAD(&arow[l]), SET1(brow[l])));
            }
            STORE(&out[j], acc);
        }
        for (; j < C1 - hc; j++) {          // leftovers: plain loop
            double sum = 0.0;
            for (int k = 0; k < (int)r2; k++) {
                double* arow = a->element(i + k - hr, 0) + (j - hc);
                double* brow = b->element(k, 0);
                for (int l = 0; l < C2; l++)
                    sum += arow[l] * brow[l];
            }
            out[j] = sum;
        }
    }
    // Borders zero padded by default
    return res;
}

matrix* weirdMul(matrix* a, matrix* b) {
    auto [r1, c1] = a->size();
    auto [r2, c2] = b->size();
    if (c1 != r2) {
        return nullptr; // Dimension mismatch
    }
    matrix* res = new matrix(r1, c2);
    // ikj order (Lab 8, Task 2): for fixed i, k the value f(a[i][k]) multiplies a whole row of b
    // and adds into a whole row of res. Both rows are contiguous, so SIMD covers j.
    // f(x) = x if x > 0.5, else x - 1  (naive: sum -= (1 - x) * b, the same number negated).
    for (uint64_t i = 0; i < r1; i++) {
        double* out = res->element(i, 0);
        for (uint64_t k = 0; k < c1; k++) {
            double x = *(a->element(i, k));
            double f = (x > 0.5) ? x : x - 1;
            vd s = SET1(f);
            double* brow = b->element(k, 0);
            uint64_t j = 0;
            for (; j + W <= c2; j += W)
                STORE(&out[j], ADD(LOAD(&out[j]), MUL(s, LOAD(&brow[j]))));
            for (; j < c2; j++)              // leftovers
                out[j] += f * brow[j];
        }
    }
    return res;
}
