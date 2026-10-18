/*
Plain (naive) versions of the three functions. DO NOT EDIT: this is the baseline.
1. outer: outer product of 2 matrices
2. convolve: convolution of a matrix with an odd-sized kernel (border stays 0)
3. weirdMul: matrix multiply where each a[i][k] is first replaced by a[i][k] or a[i][k] - 1
*/

#include "matrix.hpp"
#include <cmath>
#include <iostream>

matrix* outer(matrix *a, matrix *b) {
    auto [r1, c1] = a->size();
    auto [r2, c2] = b->size();
    matrix *res = new matrix(r1 * r2, c1 * c2);
    for (uint64_t i = 0; i < r1; i++) {
        for (uint64_t j = 0; j < c1; j++) {
            for (uint64_t p = 0; p < r2; p++) {
                for (uint64_t q = 0; q < c2; q++) {
                    *(res->element(i * r2 + p, j * c2 + q)) = (*(a->element(i, j))) * (*(b->element(p, q)));
                }
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

    // for tile (i,j) its k = -(r2 - 1)/2 to (r2 - 1)/2 and l = -(c2 - 1)/2 to (c2 - 1)/2
    // res(i,j) = sum(a(i+k, j+l) * b(k,l))
    for (int i = (r2 - 1)/2; i < r1 - (r2 - 1)/2; i++) {
        for (int j = (c2 - 1)/2; j < c1 - (c2 - 1)/2; j++) {
            double sum = 0.0;
            for (int k = -((int64_t)r2 - 1)/2; k <= ((int64_t)r2 - 1)/2; k++) {
                for (int l = -((int64_t)c2 - 1)/2; l <= ((int64_t)c2 - 1)/2; l++) {
                    sum += (*(a->element(i + k, j + l))) * (*(b->element(k + (r2 - 1)/2, l + (c2 - 1)/2)));
                }
            }
            *(res->element(i, j)) = sum;
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
    for (uint64_t i = 0; i < r1; i++) {
        for (uint64_t j = 0; j < c2; j++) {
            double sum = 0.0;
            for (uint64_t k = 0; k < c1; k++) {
                if (*(a->element(i,k)) > 0.5) {
                    sum += (*(a->element(i, k))) * (*(b->element(k, j)));
                }
                else {
                    sum -= (1 - *(a->element(i, k))) * (*(b->element(k, j)));
                }
            }
            *(res->element(i, j)) = sum;
        }
    }
    return res;
}