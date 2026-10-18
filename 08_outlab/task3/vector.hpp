#include <cstdint>

class vector{
    private:
        double *arr;
        uint64_t size = 0;
    public:
        vector(uint64_t size) {
            this->size = size;
            this->arr = new double[size];
        }
        ~vector() {
            if (this->size != 0) {
                delete[] arr;
            }
        }
        uint64_t dimension() {
            return size;
        }
        double* element(uint64_t idx) {
            return &arr[idx];
        }

};