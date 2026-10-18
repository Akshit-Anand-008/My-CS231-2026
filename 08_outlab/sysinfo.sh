#!/usr/bin/env bash
# Prints the facts that change performance numbers.
cxx=$(for c in g++-13 g++-12 g++-11 g++; do command -v $c >/dev/null && { echo $c; break; }; done)
echo "cpu:        $(lscpu | sed -n 's/^Model name: *//p')"
echo "cores:      $(lscpu | sed -n 's/^Core(s) per socket: *//p') cores, $(nproc) hardware threads"
echo "max clock:  $(lscpu | sed -n 's/^CPU max MHz: *//p' | cut -d. -f1) MHz"
echo "governor:   $(cat /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor 2>/dev/null || echo unknown)"
for c in L1d L1i L2 L3; do echo "$(printf '%-11s' "$c:") $(lscpu | sed -n "s/^$c cache: *//p")"; done
echo "simd:       $(grep -o -w -E 'sse2|avx|avx2|fma|avx512f' /proc/cpuinfo | sort -u | tr '\n' ' ')"
echo "memory:     $(free -g | awk '/^Mem:/{print $2}') GiB"
echo "os:         $(. /etc/os-release; echo $PRETTY_NAME), kernel $(uname -r)"
echo "compiler:   $cxx ($($cxx --version | head -1))"
echo "perf:       $(perf --version 2>/dev/null)"
echo "valgrind:   $(valgrind --version 2>/dev/null || echo not installed)"
echo "paranoid:   kernel.perf_event_paranoid = $(cat /proc/sys/kernel/perf_event_paranoid)"
