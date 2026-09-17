extern printf
extern exit

section .data
    fmt: db "gcd = %ld", 10, 0

section .bss
    buf: resb 256 ; so much excess space!

section .text
    global _start

; my_strtol_10(const char* str{rdi}, char** str_end{rsi}) -> rax
; write the address of the first character you do not read in [rsi]
my_strtol_10:
    dec rdi      ; makes loop cleaner
    xor eax, eax ; accumulator
    xor ecx, ecx ; sign flag (0 = positive)
    xor edx, edx
.skip_ws:
    inc rdi
    cmp byte [rdi], ' '
    je .skip_ws
.check_neg:
    cmp byte [rdi], '-'
    sete cl
    add rdi, rcx
.parse_loop:
    movzx edx, byte [rdi]
    sub dl, '0'
    cmp dl, 9
    ja .finish ; not in '0' to '9'
    lea rax, [rax+rax*4]
    lea rax, [rdx+rax*2]
    inc rdi
    jmp .parse_loop
.finish:
    mov qword [rsi], rdi
    neg rcx
    xor rax, rcx ; if rcx, rax <- ~rax
    sub rax, rcx ; if rcx, rax <- ~rax+1 == -rax
    ret


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
    sub rsp, 8

    ; read from stdin (fd 0) into buf
    xor rax, rax             ; read
    xor rdi, rdi              ; fd 0
    lea rsi, [buf]
    mov rdx, 256
    syscall

    ; parse first number
    lea rdi, [buf]
    mov rsi, rsp
    call my_strtol_10
    mov r12, rax               ; a

    ; parse second number, continuing from where first left off
    mov rdi, [rsp]
    mov rsi, rsp
    call my_strtol_10
    mov r13, rax                ; b

    mov rdi, r12
    mov rsi, r13
    call gcd

    add rsp, 8 ; stack back to 16 byte align

    lea rdi, [fmt]
    mov rsi, rax
    xor eax, eax
    call printf

    xor edi, edi
    call exit
