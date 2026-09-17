extern printf
extern exit

section .rodata
    fmt: db "is_sorted(le)=%ld is_sorted(ge)=%ld count_if(pos)=%ld", 10, 0

section .data
    arr: dd 0, 1, 2, 2, 4, 8
    .end:
    arr_len equ (arr.end-arr)/4

section .text
    global _start

; hint: see setCC commands

; le(int a{edi}, int b{esi}) -> eax (bool: a <= b)
le:
    xor eax, eax
    cmp edi, esi
    setle al
    ret

; ge(int a{edi}, int b{esi}) -> eax (bool: a >= b)
ge:
    xor eax, eax
    cmp edi, esi
    setge al
    ret

; is_positive(int x{edi}) -> eax (bool: x > 0)
is_positive:
    xor eax, eax
    cmp edi, 0
    setg al
    ret

; is_sorted(int* data{rdi}, size_t count{rsi}, FUNC cmp_func{rdx}) -> eax
; cmp_func(a, b) should return true if a is allowed to come before b.
; technically FUNC as a type is bool(*)(int, int) in C but its syntax is ugly
is_sorted:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8               ; align stack for calls

    cmp rsi, 1
    jbe .sorted                ; 0 or 1 elements: trivially sorted

    mov rbx, rdi                ; data
    mov r12, rsi                 ; count
    mov r13, rdx                  ; cmp_func
    xor r14, r14                   ; index i = 0

.loop:
    mov rax, r14
    add rax, 1
    cmp rax, r12
    jge .sorted                     ; i+1 >= count -> done, sorted

    mov edi, [rbx + r14*4]
    mov esi, [rbx + r14*4 + 4]
    call r13

    test eax, eax
    jz .not_sorted

    inc r14
    jmp .loop

.sorted:
    mov eax, 1
    jmp .ret
.not_sorted:
    xor eax, eax
.ret:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; count_if(int* data{rdi}, size_t count{rsi}, FUNC pred{rdx}) -> rax
; technically FUNC as a type is bool(*)(int) in C but its syntax is ugly
count_if:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8

    mov rbx, rdi              ; data
    mov r12, rsi                ; count
    mov r13, rdx                  ; pred
    xor r14, r14                    ; index i
    xor r15, r15                    ; running count

.loop:
    cmp r14, r12
    jge .done

    mov edi, [rbx + r14*4]
    call r13

    test eax, eax
    jz .skip
    inc r15
.skip:
    inc r14
    jmp .loop

.done:
    mov rax, r15
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

_start:
    and rsp, -16

    lea rdi, [rel arr]
    mov rsi, arr_len
    lea rdx, [rel le]
    call is_sorted
    mov r12, rax               ; is_sorted(le)

    lea rdi, [rel arr]
    mov rsi, arr_len
    lea rdx, [rel ge]
    call is_sorted
    mov r13, rax                ; is_sorted(ge)

    lea rdi, [rel arr]
    mov rsi, arr_len
    lea rdx, [rel is_positive]
    call count_if
    mov r14, rax                  ; count_if(pos)

    lea rdi, [rel fmt]
    mov rsi, r12
    mov rdx, r13
    mov rcx, r14
    xor eax, eax
    call printf

    ; exit(100*is_sorted(le) + 10*is_sorted(ge) + count_if(pos))
    mov rax, r12
    imul rax, rax, 100
    mov rbx, r13
    imul rbx, rbx, 10
    add rax, rbx
    lea rdi, [rax+r14]

    call exit
