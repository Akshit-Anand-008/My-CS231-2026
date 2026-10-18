// heat_fixed.cpp -- same simulation as heat_base.cpp with two changes, marked FIX 1 and FIX 2.
// DO NOT EDIT: you only measure this program.
// Run: ./heat_fixed.out [N] [STEPS] [OUTFILE]   (writes OUTFILE as CSV only if it is given)

#include <bits/stdc++.h>
using namespace std;

#define IDX(i, j, N) ((i) * (N) + (j))

int main(int argc, char** argv) {
    size_t N = (argc > 1) ? stoul(argv[1]) : 1024;   // grid size
    size_t STEPS = (argc > 2) ? stoul(argv[2]) : 50;
    string out_file = (argc > 3) ? argv[3] : "";

    double* grid = static_cast<double*>(malloc(N * N * sizeof(double)));
    double* new_grid = static_cast<double*>(malloc(N * N * sizeof(double)));
    if (!grid || !new_grid) {
        cerr << "Allocation failed!\n";
        return 1;
    }

    // initialize grid with random values between 0 and 1
    mt19937 rng(42);
    uniform_real_distribution<double> dist(0.0, 1.0);
    for (size_t i = 0; i < N * N; ++i)
        grid[i] = dist(rng);
    // the border cells never change, so both buffers start equal
    memcpy(new_grid, grid, N * N * sizeof(double));

    // random "hot spots" that get a little hotter every step
    size_t hot_spots = 8;
    vector<pair<size_t, size_t>> hot_indices;
    for (size_t k = 0; k < hot_spots; ++k)
        hot_indices.emplace_back(rng() % N, rng() % N);

    // FIX 2: mark the hot cells once, in a table with one entry per cell.
    // Checking a cell is now one load instead of a search through all 8 pairs.
    vector<char> is_hot(N * N, 0);
    for (auto [i, j] : hot_indices)
        is_hot[IDX(i, j, N)] = 1;

    cout << "Running heat simulation on " << N << "x" << N << " grid for "
         << STEPS << " steps...\n";
    cout << setprecision(12);

    auto t0 = chrono::steady_clock::now();

    // Main simulation: each cell becomes the average of its 4 neighbours
    for (size_t t = 0; t < STEPS; ++t) {
        // FIX 1: i (the row) is the outer loop and j (the column) the inner one,
        // so the inner loop walks along a row: consecutive addresses, 8 doubles per cache line.
        for (size_t i = 1; i < N - 1; ++i) {
            for (size_t j = 1; j < N - 1; ++j) {
                new_grid[IDX(i, j, N)] = 0.25 * (
                    grid[IDX(i - 1, j, N)] +
                    grid[IDX(i + 1, j, N)] +
                    grid[IDX(i, j - 1, N)] +
                    grid[IDX(i, j + 1, N)]
                );

                if (is_hot[IDX(i, j, N)]) {
                    new_grid[IDX(i, j, N)] += 0.01;
                }
            }
        }

        swap(grid, new_grid);
    }

    auto t1 = chrono::steady_clock::now();

    double checksum = 0.0;
    for (size_t i = 0; i < N * N; ++i)
        checksum += grid[i];
    cout << "Final checksum: " << checksum << "\n";
    cout << "time_ms = " << chrono::duration<double, milli>(t1 - t0).count() << "\n";

    if (!out_file.empty()) {
        ofstream fout(out_file);
        for (size_t i = 0; i < N; ++i) {
            for (size_t j = 0; j < N; ++j) {
                fout << grid[IDX(i, j, N)];
                if (j + 1 != N) fout << ",";
            }
            fout << "\n";
        }
        cout << "Final grid written to: " << out_file << "\n";
    }

    free(grid);
    free(new_grid);
    return 0;
}
