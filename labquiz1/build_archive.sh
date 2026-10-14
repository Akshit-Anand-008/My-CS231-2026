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
VALID_PATTERN="^(210050102|2[345]b(090[1-9]|09[1-9][0-9]|10[0-9][0-9]|1100))$"

if ! echo "$ROLL_NO" | grep -qE "$VALID_PATTERN" ; then
    printf "${RED}Error: Invalid student ID. Please check the ID and try again.${NC}\n" >&2
    exit 1
fi

mkdir -p "$ROLL_NO"

FILES=(./task1/tb_task1.v ./task1/expected_output.txt ./task1/task1.v ./task2/tests/12_input.txt ./task2/tests/06_output.txt ./task2/tests/13_output.txt ./task2/tests/05_output.txt ./task2/tests/01_output.txt ./task2/tests/15_input.txt ./task2/tests/09_output.txt ./task2/tests/10_output.txt ./task2/tests/03_output.txt ./task2/tests/08_input.txt ./task2/tests/07_output.txt ./task2/tests/03_input.txt ./task2/tests/12_output.txt ./task2/tests/04_output.txt ./task2/tests/14_input.txt ./task2/tests/16_input.txt ./task2/tests/11_input.txt ./task2/tests/02_input.txt ./task2/tests/14_output.txt ./task2/tests/01_input.txt ./task2/tests/10_input.txt ./task2/tests/02_output.txt ./task2/tests/04_input.txt ./task2/tests/16_output.txt ./task2/tests/15_output.txt ./task2/tests/07_input.txt ./task2/tests/13_input.txt ./task2/tests/06_input.txt ./task2/tests/08_output.txt ./task2/tests/09_input.txt ./task2/tests/05_input.txt ./task2/tests/11_output.txt ./task2/power_sum.s ./task2/digit_fn.o ./task3/elevator.v ./task3/tb_task3.v ./task3/expected_output_C.txt ./task3/expected_output_A_B.txt)

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
