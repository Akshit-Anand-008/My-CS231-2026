#!/usr/bin/env bash
set -e

RED=$(printf '\033[31m')
GREEN=$(printf '\033[32m')
NC=$(printf '\033[0m')

read -rp "Enter Student Roll Number: " ROLL_NO
if [ -z "$ROLL_NO" ]; then
    printf "${RED}Error: Roll number cannot be empty.${NC}\n" >&2
    exit 1
fi

# Validate Roll Number against allowed range (901 to 1100)
VALID_PATTERN="^(210050102|23b0919|24b1017|24b1068|25b(090[1-9]|09[1-9][0-9]|10[0-9][0-9]|1100))$"

if ! echo "$ROLL_NO" | grep -qE "$VALID_PATTERN" ; then
    printf "${RED}Error: Invalid student ID. Please check the ID and try again.${NC}\n" >&2
    exit 1
fi

mkdir -p "$ROLL_NO"

FILES=(./task1/heat_fixed.cpp ./task1/heat_lookup.cpp ./task1/heat_base.cpp ./task1/answers.txt ./task2/changes.txt ./task2/repeated_array.cpp ./task2/findings.txt ./task2/weird_matrix.cpp ./task3/matrix.hpp ./task3/changes.txt ./task3/mask.cpp ./task3/naive.cpp ./task3/findings.txt ./task3/vector.hpp ./task3/optim.cpp ./task3/main.cpp ./task4/changes.txt ./task4/grid_bfs.cpp ./task4/expected_output.txt ./task4/findings.txt ./task5/changes.txt ./task5/packets.cpp ./task5/expected_output.txt ./task5/findings.txt ./task6/generate.py ./task6/run.sh ./task6/spawn_sim.cpp ./task6/spawn_ref.cpp)

echo "Packaging assignment files..."
for file in "${FILES[@]}"; do
    if [ -e "$file" ] || [ -L "$file" ]; then
        mkdir -p "$ROLL_NO/$(dirname "$file")"
        cp -RP "$file" "$ROLL_NO/$file"
        printf "  ${GREEN}[+] Copied:${NC} %s\n" "$file"
    else
        printf "${RED}Error: Required file or symlink missing: %s${NC}\n" "$file" >&2
        rm -rf "$ROLL_NO"
        exit 1
    fi
done

tar -czf "${ROLL_NO}.tar.gz" "$ROLL_NO"
rm -rf "$ROLL_NO"
printf "${GREEN}Successfully created ${ROLL_NO}.tar.gz${NC}\n"
