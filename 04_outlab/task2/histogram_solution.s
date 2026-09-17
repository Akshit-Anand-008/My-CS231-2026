section .data
    text:
        db "mississippi"
    .end:
    text_len equ (text.end - text)

    counts: times 26 dd 0

    ;; the most common letter's count is 4 by default

section .text
    global _start

_start:
    xor rcx, rcx        ; index into text
.count_loop:
    cmp rcx, text_len
    jge .find_max

    movzx eax, byte [text + rcx]
    sub eax, 'a'
    inc dword [counts + 4*rax]

    inc rcx
    jmp .count_loop

.find_max:
    xor rdi, rdi        ; running max count
    xor rcx, rcx        ; index into counts
.max_loop:
    cmp rcx, 26
    jge .done

    mov eax, [counts + 4*rcx]
    cmp eax, edi
    jle .max_advance
    mov edi, eax

.max_advance:
    inc rcx
    jmp .max_loop

.done:
    mov rax, 60
    syscall
