extern printf
extern exit
extern localtime_r

section .data
    DDMMYYYY_FMT: db "%02d/%02d/%04d ", 0
    hhmmss_FMT: db "%02d:%02d:%02d", 10, 0

section .bss
    epoch_secs: resq 1

    tm_buf:
        .tm_sec: resd 1
        .tm_min: resd 1
        .tm_hour: resd 1
        .tm_mday: resd 1
        .tm_mon: resd 1
        .tm_year: resd 1
        .tm_wday: resd 1
        .tm_yday: resd 1
        .tm_isdst: resd 1
        resd 1
        .tm_gmtoff: resq 1
        .tm_zone: resq 1

section .text
    global _start

_start:
    and rsp, -16

    ; time(&epoch_secs) via syscall 201
    mov rax, 201
    lea rdi, [epoch_secs]
    syscall

    ; localtime_r(&epoch_secs, &tm_buf)
    lea rdi, [epoch_secs]
    lea rsi, [tm_buf]
    call localtime_r

    ; printf(DDMMYYYY_FMT, tm_mday, tm_mon+1, tm_year+1900)
    lea rdi, [DDMMYYYY_FMT]
    mov esi, [tm_buf.tm_mday]
    mov edx, [tm_buf.tm_mon]
    add edx, 1
    mov ecx, [tm_buf.tm_year]
    add ecx, 1900
    xor eax, eax
    call printf

    ; printf(hhmmss_FMT, tm_hour, tm_min, tm_sec)
    lea rdi, [hhmmss_FMT]
    mov esi, [tm_buf.tm_hour]
    mov edx, [tm_buf.tm_min]
    mov ecx, [tm_buf.tm_sec]
    xor eax, eax
    call printf

    xor edi, edi
    call exit
