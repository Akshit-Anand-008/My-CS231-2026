section .bss
    buf: resb 4096

section .text
    global _start

; process_fd(fd{rdi}) - reads from fd and writes to stdout until EOF
process_fd:
    push rbp
    mov rbp, rdi
.loop:
    xor rax, rax   ; read
    mov rdi, rbp   ; fd
    lea rsi, [buf] ; buffer
    mov rdx, 4096  ; buffer_len
    syscall

    test rax, rax
    jle .done      ; EOF (0) or error (<0)

    mov rdx, rax   ; number of bytes read
    mov rax, 1     ; write
    mov rdi, 1     ; stdout
    lea rsi, [buf] ; buffer
    syscall

    jmp .loop
.done:
    pop rbp
    ret

_start:
    mov r15, [rsp]    ; argc
    dec r15           ; first is always program's name

    lea r12, [rsp+16] ; first filename == argv[1]
    xor r13, r13      ; curr-idx

.arg_loop:
    cmp r13, r15
    jge .done_all

    mov rdi, [r12 + r13*8] ; argv[1+i]
    xor eax, eax           ; be ready to be stdin
    cmp word [rdi], '-'    ; "-\0" in little endian is equal to '-'
    je .process_file       ; skip to processing, no need to open

.open_file:
    mov rax, 2   ; open
    ; filename in rdi
    xor rsi, rsi ; O_RDONLY
    xor rdx, rdx ; 0 since not creating file
    syscall

    test rax, rax
    js .continue

.process_file:
    mov rdi, rax ; fd
    push rax
    call process_fd

    mov rax, 3 ; close
    pop rdi    ; fd
    syscall

.continue:
    inc r13
    jmp .arg_loop

.done_all:
    mov rax, 60
    xor rdi, rdi
    syscall
