extern printf
extern exit

section .rodata
    fmt_move: db "Move disk %d from %s to %s", 10, 0
    fmt_count: db "Total moves: %ld", 10, 0
    pole_a: db "A", 0
    pole_b: db "B", 0
    pole_c: db "C", 0

section .data
    move_count: dq 0

section .text
    global _start

; towers_of_hanoi(const char* src{rdi}, const char* dest{rsi}, const char* aux{rdx}, size_t num_discs{rcx})
towers_of_hanoi:
    test rcx, rcx
    jz .done ; num_discs == 0, nothing to move
    
    push r12
    push r13
    push r14
    push r15
    push rbp ; extra for stack-align

    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    
    ; rdi has src
    mov rsi, r14 ; aux
    mov rdx, r13 ; dest
    dec rcx      ; num_discs - 1
    call towers_of_hanoi

    lea rdi, [fmt_move]
    mov rsi, r15
    mov rdx, r12
    mov rcx, r13
    call printf
    inc qword [move_count]

    mov rdi, r14 ; aux
    mov rsi, r13 ; dest
    mov rdx, r12 ; src
    lea rcx, [r15-1] ; num_discs-1
    call towers_of_hanoi

    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
.done:
    ret

_start:
    and rsp, -16

    lea rdi, [pole_a]
    lea rsi, [pole_c]
    lea rdx, [pole_b]
    mov rcx, 3
    call towers_of_hanoi

    lea rdi, [fmt_count]
    mov rsi, [move_count]
    xor eax, eax
    call printf

    mov rdi, [move_count]
    call exit
