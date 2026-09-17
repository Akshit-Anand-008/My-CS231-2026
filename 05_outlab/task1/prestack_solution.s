section .rodata
    error_msg: db "There should be 3 command line arguments!",10
    .end: db 0 ; null terminator for the TA's mental peace
    error_msg_len equ (error_msg.end-error_msg)

section .text
    global _start

; my_strlen(const char* str{rdi}) -> rax (not counting the null terminator)
my_strlen:
    xor rax, rax
.loop:
    cmp byte [rdi+rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

; my_atoi(const char* str{rdi}) -> rax (handles an optional leading '-')
my_atoi:
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
    mov rax, [rsp]           ; argc
    cmp rax, 3
    je .argc_ok

    ; print error message and exit(1)
    mov rax, 1
    mov rdi, 2                ; stderr
    lea rsi, [rel error_msg]
    mov rdx, error_msg_len
    syscall
    mov rax, 60
    mov rdi, 1
    syscall

.argc_ok:
    mov rbx, [rsp+16]        ; argv[1]
    mov r12, [rsp+24]        ; argv[2]

    ; print argv[1] as-is
    mov rdi, rbx
    call my_strlen
    mov rdx, rax             ; length
    mov rax, 1                ; write
    mov rdi, 1                 ; stdout
    mov rsi, rbx
    syscall

    ; exit(gcd(atoi(argv[1]), atoi(argv[2])))
    mov rdi, rbx
    call my_atoi
    mov rbx, rax
    mov rdi, r12
    call my_atoi
    mov rsi, rax
    mov rdi, rbx
    call gcd

    mov rdi, rax
    mov rax, 60
    syscall
