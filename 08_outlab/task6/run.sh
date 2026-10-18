#!/usr/bin/env bash
# Task 6 (optional). Usage, from the 08_outlab folder:
#   bash task6/run.sh grids   build the inputs (needs python3 + numpy) and the expected outputs from spawn_ref.out
#   bash task6/run.sh check   run spawn_sim.out on every grid, compare with the expected output, print the speedup
set -e
GENS=1000
dir=task6/grids
case $1 in
grids)
    mkdir -p $dir
    python3 task6/generate.py --output-dir $dir --sizes 512,1024 > /dev/null
    : > $dir/ref_ms.txt
    for f in $dir/public_*_[0-9]*.bin; do
        case $f in *.expected.bin) continue ;; esac
        ms=$(./spawn_ref.out "$f" "${f%.bin}.expected.bin" $GENS | cut -d' ' -f1)
        echo "$(basename "$f") $ms" >> $dir/ref_ms.txt
        echo "reference: $(basename "$f")  $ms ms"
    done ;;
check)
    [ -f $dir/ref_ms.txt ] || { echo "run: make task6-grids  (first time only)"; exit 1; }
    while read name ref_ms; do
        f=$dir/$name
        ms=$(./spawn_sim.out "$f" $dir/out.bin $GENS | cut -d' ' -f1)
        if cmp -s $dir/out.bin "${f%.bin}.expected.bin"; then verdict='\033[32mPASS\033[0m'; else verdict='\033[31mFAIL\033[0m'; fi
        printf "$verdict -- %-34s %10s ms  (reference %s ms, %sx)\n" "$name" "$ms" "$ref_ms" \
            "$(awk -v a="$ref_ms" -v b="$ms" 'BEGIN { printf "%.1f", a / b }')"
    done < $dir/ref_ms.txt
    rm -f $dir/out.bin ;;
*)
    echo "usage: bash task6/run.sh grids|check"; exit 1 ;;
esac
