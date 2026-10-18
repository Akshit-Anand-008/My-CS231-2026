#!/usr/bin/env bash
# Checks that the parts of a file you must not edit are unchanged, by comparing a hash.
# Usage: bash check_fixed.sh markers|whole|build FILE EXPECTED_HASH
#   markers: the file without the /* ... BELOW */ ... /* ... ABOVE */ spaces
#   whole:   the whole file
#   build:   only the build_* functions (task 5)
mode=$1 file=$2 want=$3
case $mode in
    markers) part="$file outside the marked spaces"
             got=$(sed -E '/^ *\/\* .*BELOW.* \*\/$/,/^ *\/\* .*ABOVE.* \*\/$/d' "$file" | sha256sum | cut -c1-16) ;;
    whole)   part="$file"
             got=$(sha256sum < "$file" | cut -c1-16) ;;
    build)   part="the build_* functions in $file"
             got=$(sed -E -n '/^(\[\[maybe_unused\]\] )?static std::vector<[A-Za-z]*> build_[a-z_]*\(/,/^}/p' "$file" | sha256sum | cut -c1-16) ;;
esac
if [ "$got" = "$want" ]; then
    printf '\033[32mPASS\033[0m -- %s: unchanged\n' "$part"
else
    printf '\033[31mFAIL\033[0m -- %s: edited (this part must stay as given)\n' "$part"
fi
