section .data
    values:
        dq 4, 4, 4, 7, 7, 2, 2, 2, 2, 9, 9, 1, 7, 7, 7
    .end:
    n equ (values.end - values)/8

    ;; longest run of consecutive equal values is 4 by default

section .text
    global _start

_start:
    mov rdi, 1          ; best streak found so far
    mov rsi, 1          ; current streak length
    mov rcx, 1          ; index, starting at the 2nd element

.loop:
    cmp rcx, n
    jge .done

    mov rax, [values + 8*rcx]
    mov rdx, [values + 8*rcx - 8]
    cmp rax, rdx
    jne .reset

    inc rsi
    cmp rsi, rdi
    jle .advance
    mov rdi, rsi
    jmp .advance

.reset:
    mov rsi, 1

.advance:
    inc rcx
    jmp .loop

.done:
    mov rax, 60
    syscall
