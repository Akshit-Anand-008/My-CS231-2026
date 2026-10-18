#include <cstdint>
#include <utility>
class matrix {
    private:
        uint64_t rows;
        uint64_t cols;
        double* data;    
    public:
        matrix(uint64_t r, uint64_t c) : rows(r), cols(c) {
            data = new double[rows * cols](); // initializes matrices to 0s
        }
        ~matrix() {
            delete[] data;
        }
        std::pair<uint64_t, uint64_t> size() const {
            return {rows, cols};
        }
        double* element(uint64_t i, uint64_t j) {
            return &data[i * cols + j];
        }
};

matrix* transpose(matrix *a);
matrix* add(matrix *a, matrix *b);
matrix* sub(matrix *a, matrix *b);
matrix* matmul(matrix *a, matrix *b);
matrix* outer(matrix *a, matrix *b);
matrix* convolve(matrix *a, matrix *b);
matrix* weirdMul(matrix *a, matrix *b); 