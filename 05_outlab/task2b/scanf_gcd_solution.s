extern printf
extern exit
extern scanf

section .rodata
    infmt: db "%ld %ld", 0
    outfmt: db "gcd = %ld", 10, 0

section .bss
    val_a: resq 1
    val_b: resq 1

section .text
    global _start

; gcd(int64_t a{rdi}, int64_t b{rsi}) -> rax
gcd:
    test rsi, rsi
    jz .base
    mov rax, rdi
    cqo
    idiv rsi
    mov rdi, rsi
    mov rsi, rdx
    jmp gcd
.base:
    mov rax, rdi
    ret

_start:
    and rsp, -16

    lea rdi, [infmt]
    lea rsi, [val_a]
    lea rdx, [val_b]
    xor eax, eax
    call scanf

    mov rdi, [val_a]
    mov rsi, [val_b]
    call gcd

    lea rdi, [outfmt]
    mov rsi, rax
    xor eax, eax
    call printf

    xor edi, edi
    call exit
