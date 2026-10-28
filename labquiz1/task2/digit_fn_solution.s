; digit_fn(uint64_t d{rdi}) -> rax = d ** d
;
; Contract:
;   Input:
;       rdi = d, where 0 <= d <= 9
;
;   Return:
;       rax = d ** d
;       0 ** 0 = 1
;
;   For d = 0, 1, 2, 5, 9:
;       - preserves all general-purpose registers except rax
;       - preserves all memory
;       - RFLAGS may be clobbered
;
;   For all other inputs:
;       - destroys all caller-saved general-purpose registers
;         (rax contains the return value)
;       - may destroy memory below the caller's rsp
;       - preserves all callee-saved registers
;       - preserves all memory at or above the caller's rsp
;
; System V AMD64 calling convention.

section .rodata
    pow_lut:
        dq 1, 1, 4, 27, 256, 3125, 46656, 823543, 16777216, 387420489

section .text
    global digit_fn

digit_fn:
    ; ------------------------------------------------------------
    ; Special inputs: determine whether we must preserve everything.
    ; These instructions only modify RFLAGS.
    ; ------------------------------------------------------------
    cmp     rdi, 9
    ja      .ub_trap

    lea     rax, [rel pow_lut]
    mov     rax, [rax + rdi*8]

    cmp     rdi, 0
    je      .preserve

    cmp     rdi, 1
    je      .preserve

    cmp     rdi, 2
    je      .preserve

    cmp     rdi, 5
    je      .preserve

    cmp     rdi, 9
    je      .preserve

    ; ------------------------------------------------------------
    ; Destructive path.
    ; ------------------------------------------------------------


    mov     r11, 0x8BADF00D8BADF00D
    mov     rdi, 0xDEADC0DEDEADC0DE
    mov     rsi, 0x4B1D4B1D4B1D4B1D
    mov     rdx, 0xBAAAAAAAAAAAAAAD
    mov     rcx, 0xBADBADBADBADBAAD
    mov     r8,  0xBAD2222222222222
    mov     r9,  0xBADDCAFEBADDCAFE
    mov     r10, 0xC00010FFC00010FF

    mov     [rsp-8],  r11
    mov     [rsp-16], rdi
    mov     [rsp-24], r9
    mov     [rsp-32], rdx

    ret

    ; ------------------------------------------------------------
    ; Non-clobbering paths.
    ;
    ; Only RAX is changed, to hold the return value.
    ; All GPRs other than RAX and all memory remain untouched.
    ; ------------------------------------------------------------

.preserve:
    ret

.ub_trap:
    mov rax, 0xBAAAAAAD
    ret