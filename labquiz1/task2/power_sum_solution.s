    global _start
    extern digit_fn

; ================================================================
;                  DO NOT EDIT ABOVE THIS LINE
; ================================================================

section .text

; power_sum: rdi = pointer to a NUL-terminated string, return total in rax.
power_sum:
    push    rbx
    push    r12
    xor     ebx, ebx           ; total  (callee-saved: survives digit_fn)
    mov     r12, rdi           ; cursor (callee-saved: survives digit_fn)
.loop:
    movzx   eax, byte [r12]
    sub     al, '0'
    cmp     al, 9
    ja      .done              ; not a digit (also catches the NUL)
    movzx   edi, al
    call    digit_fn
    add     rbx, rax
    inc     r12
    jmp     .loop
.done:
    mov     rax, rbx
    pop     r12
    pop     rbx
    ret

; ================================================================
;                  DO NOT EDIT BELOW THIS LINE
; ================================================================

section .bss
    inbuf   resb 4096

section .text
_start:
    xor     eax, eax                ; read(0, inbuf, 4096)
    xor     edi, edi
    lea     rsi, [rel inbuf]
    mov     edx, 4095
    syscall
    test    rax, rax
    js      .die

    ; .bss starts zeroed and read() only ever writes the bytes it reads, so
    ; whatever comes right after the input is already 0 -- no need to write
    ; a terminator ourselves.
    lea     rdi, [rel inbuf]
    call    power_sum               ; rax = total

    mov     rcx, rsp                ; format rax as decimal + '\n' on the stack
    dec     rsp
    mov     byte [rsp], 10
    mov     r8d, 10
.emit:
    xor     edx, edx
    div     r8
    dec     rsp
    add     dl, '0'
    mov     [rsp], dl
    test    rax, rax
    jnz     .emit

    mov     eax, 1                  ; write(1, rsp, rcx - rsp)
    mov     edi, 1
    mov     rsi, rsp
    mov     rdx, rcx
    sub     rdx, rsp
    syscall

    xor     edi, edi               ; exit(0)
    mov     eax, 60
    syscall
.die:
    mov     edi, 1                 ; exit(1)
    mov     eax, 60
    syscall
