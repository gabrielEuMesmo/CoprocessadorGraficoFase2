    .syntax unified
    .arch armv7-a
    .arm
    .text
    .align 2

    #include "hps_0.h"

    .equ SYS_OPEN,      5
    .equ SYS_CLOSE,     6
    .equ SYS_MMAP2,     192
    .equ SYS_MUNMAP,    91

    .equ O_RDWR_SYNC,     0x101002
    .equ PROT_READ_WRITE, 3
    .equ MAP_SHARED,      1

    .equ HW_REGS_BASE,    0xFF200000
    .equ HW_REGS_SPAN,    0x00200000

    .global abrir_memoria
    .type   abrir_memoria, %function
    .global fechar_memoria
    .type   fechar_memoria, %function
    .global enviar_instrucao
    .type   enviar_instrucao, %function

    .global enviar_reset
    .type   enviar_reset, %function
    .global enviar_sprite_info
    .type   enviar_sprite_info, %function
    .global enviar_sprite_config
    .type   enviar_sprite_config, %function
    .global enviar_pol_info
    .type   enviar_pol_info, %function
    .global enviar_pol_config
    .type   enviar_pol_config, %function
    .global enviar_bg_info
    .type   enviar_bg_info, %function
    .global enviar_toggle_layer
    .type   enviar_toggle_layer, %function

    .extern puts
    .extern printf
    .extern fflush

@ =============================================================================
@ abrir_memoria
@ Entrada: nenhuma
@ Retorno: r0 -> ponteiro virtual base (ou -1 em erro)
@ Efeito : preenche g_fd e g_virtual_base
@ =============================================================================
abrir_memoria:
    push {r4, r5, r6, r7, r8, lr}  @ 24 bytes, pilha continua alinhada em 8

    ldr r0, =msg_abrir_init
    bl puts
    mov r0, #0
    bl fflush

    @ ---- open("/dev/mem", O_RDWR | O_SYNC) ----
    ldr r0, =dev_mem_path
    ldr r1, =O_RDWR_SYNC
    mov r2, #0
    mov r7, #SYS_OPEN
    svc #0

    cmn r0, #4096                  @ erro se r0 estiver em [-4096, -1]
    bcs erro_abrir

    mov r6, r0                     @ r6 = fd
    ldr r1, =g_fd
    str r6, [r1]                   @ g_fd = fd

    ldr r0, =msg_open_ok
    mov r1, r6
    bl printf
    mov r0, #0
    bl fflush

    @ ---- mmap2(NULL, SPAN, PROT_RW, MAP_SHARED, fd, base>>12) ----
    mov r0, #0
    ldr r1, =HW_REGS_SPAN
    mov r2, #PROT_READ_WRITE
    mov r3, #MAP_SHARED
    mov r4, r6                     @ arg5 = fd
    ldr r5, =HW_REGS_BASE
    lsr r5, r5, #12                @ arg6 = offset em paginas (0xFF200)
    mov r7, #SYS_MMAP2
    svc #0

    cmn r0, #4096
    bcs erro_mmap

    mov r5, r0                     @ r5 = virtual_base
    ldr r1, =g_virtual_base
    str r5, [r1]                   @ g_virtual_base = virtual_base

    ldr r0, =msg_mmap_ok
    mov r1, r5
    bl printf
    mov r0, #0
    bl fflush

    mov r0, r5                     @ retorno
    pop {r4, r5, r6, r7, r8, pc}

erro_mmap:
    ldr r0, =msg_err_mmap
    bl puts
    mov r0, #0
    bl fflush

    mov r0, r6                     @ fecha o fd
    mov r7, #SYS_CLOSE
    svc #0

    mvn r0, #0                     @ g_fd = -1
    ldr r1, =g_fd
    str r0, [r1]
    b erro_retorno

erro_abrir:
    ldr r0, =msg_err_open
    bl puts
    mov r0, #0
    bl fflush

erro_retorno:
    mov r0, #-1
    pop {r4, r5, r6, r7, r8, pc}

    .ltorg

@ =============================================================================
@ fechar_memoria
@ Entrada: nenhuma (usa g_virtual_base e g_fd)
@ =============================================================================
fechar_memoria:
    push {r4, r5, r7, lr}

    ldr r5, =g_virtual_base
    ldr r0, [r5]                   @ r0 = virtual_base
    ldr r1, =HW_REGS_SPAN
    mov r7, #SYS_MUNMAP
    svc #0

    mov r0, #0
    str r0, [r5]                   @ g_virtual_base = 0

    ldr r4, =g_fd
    ldr r0, [r4]                   @ r0 = fd
    mov r7, #SYS_CLOSE
    svc #0

    mvn r0, #0
    str r0, [r4]                   @ g_fd = -1

    pop {r4, r5, r7, pc}

@ =============================================================================
@ enviar_instrucao
@ Entrada: r0 -> instrucao, r1 -> virtual_base
@ =============================================================================
enviar_instrucao:
    push {r4, r5, r6, lr}
    mov r4, r0                     @ r4 = instrucao
    mov r5, r1                     @ r5 = virtual_base

    ldr r0, =msg_inst_start
    mov r1, r4
    mov r2, r5
    bl printf
    mov r0, #0
    bl fflush

    ldr r0, =msg_wait_ready
    bl puts
    mov r0, #0
    bl fflush

wait_ready:
    ldr r2, [r5, #(PIO_READY_BASE & 0x1FFFFF)]
    cmp r2, #0
    beq wait_ready

    ldr r0, =msg_ready_ok
    bl puts
    mov r0, #0
    bl fflush

    str r4, [r5, #(PIO_INST_BASE & 0x1FFFFF)]
    mov r2, #1
    str r2, [r5, #(PIO_ATIVA_BASE & 0x1FFFFF)]

    ldr r0, =msg_wait_valid1
    bl puts
    mov r0, #0
    bl fflush

wait_valid_1:
    ldr r2, [r5, #(PIO_VALID_BASE & 0x1FFFFF)]
    cmp r2, #0
    beq wait_valid_1

    ldr r0, =msg_valid1_ok
    bl puts
    mov r0, #0
    bl fflush

    mov r2, #1
    str r2, [r5, #(PIO_CLEAR_BASE & 0x1FFFFF)]
    mov r2, #0
    str r2, [r5, #(PIO_ATIVA_BASE & 0x1FFFFF)]

    ldr r0, =msg_wait_valid0
    bl puts
    mov r0, #0
    bl fflush

wait_valid_0:
    ldr r2, [r5, #(PIO_VALID_BASE & 0x1FFFFF)]
    cmp r2, #1
    beq wait_valid_0

    ldr r0, =msg_valid0_ok
    bl puts
    mov r0, #0
    bl fflush

    mov r2, #0
    str r2, [r5, #(PIO_CLEAR_BASE & 0x1FFFFF)]

    ldr r0, =msg_inst_end
    bl puts
    mov r0, #0
    bl fflush

    pop {r4, r5, r6, pc}

    .ltorg

@ =============================================================================
@ Funcoes de instrucao: montam a palavra de 32 bits e chamam enviar_instrucao
@ (tail call: o lr do chamador e preservado)
@ =============================================================================

@ void enviar_reset(void)
enviar_reset:
    mov r0, #(1 << 29)
    ldr r1, =g_virtual_base
    ldr r1, [r1]
    b   enviar_instrucao

@ void enviar_sprite_info(camada, id, x, y)
enviar_sprite_info:
    mov r12, #(2 << 29)
    bfi r12, r0, #23, #6
    bfi r12, r1, #17, #6
    bfi r12, r2, #8,  #9
    bfi r12, r3, #0,  #8
    mov r0, r12
    ldr r1, =g_virtual_base
    ldr r1, [r1]
    b   enviar_instrucao

@ void enviar_sprite_config(camada, visivel, flipx, flipy)
enviar_sprite_config:
    mov r12, #(3 << 29)
    bfi r12, r0, #3, #6
    bfi r12, r1, #2, #1
    bfi r12, r2, #1, #1
    bfi r12, r3, #0, #1
    mov r0, r12
    ldr r1, =g_virtual_base
    ldr r1, [r1]
    b   enviar_instrucao

@ void enviar_pol_info(camada, vertice, x, y)
enviar_pol_info:
    mov r12, #(4 << 29)
    bfi r12, r0, #19, #2
    bfi r12, r1, #17, #2
    bfi r12, r2, #8,  #9
    bfi r12, r3, #0,  #8
    mov r0, r12
    ldr r1, =g_virtual_base
    ldr r1, [r1]
    b   enviar_instrucao

@ void enviar_pol_config(camada, visivel, trapezio, cor)
enviar_pol_config:
    mov r12, #(5 << 29)
    bfi r12, r0, #10, #2
    bfi r12, r1, #9,  #1
    bfi r12, r2, #8,  #1
    bfi r12, r3, #0,  #8
    mov r0, r12
    ldr r1, =g_virtual_base
    ldr r1, [r1]
    b   enviar_instrucao

@ void enviar_bg_info(funcao, roll, x, y, cor)   cor = 5o arg, em [sp]
enviar_bg_info:
    mov r12, #(6 << 29)
    bfi r12, r0, #21, #1
    bfi r12, r1, #19, #2
    bfi r12, r2, #13, #6
    bfi r12, r3, #8,  #5
    ldr r0, [sp]                   @ cor (sp ainda e o do chamador)
    bfi r12, r0, #0,  #8
    mov r0, r12
    ldr r1, =g_virtual_base
    ldr r1, [r1]
    b   enviar_instrucao

@ void enviar_toggle_layer(layer)
@ opcode 7 | layer[0]
enviar_toggle_layer:
    mov r12, #(7 << 29)
    bfi r12, r0, #0, #1            @ layer & 1
    mov r0, r12
    ldr r1, =g_virtual_base
    ldr r1, [r1]
    b   enviar_instrucao

    .ltorg

@ =============================================================================
@ Dados
@ =============================================================================
    .data
    .align 2
    .global g_virtual_base
g_virtual_base:
    .word 0
g_fd:
    .word -1
    .section .rodata
dev_mem_path:     .asciz "/dev/mem"

msg_abrir_init:   .asciz "[ASM abrir_memoria] Solicitando /dev/mem..."
msg_open_ok:      .asciz "[ASM abrir_memoria] /dev/mem aberto com SUCESSO. fd = %d\n"
msg_mmap_ok:      .asciz "[ASM abrir_memoria] mmap2 realizado com SUCESSO. virtual_base = %p\n"
msg_err_open:     .asciz "[ASM abrir_memoria] ERRO na chamada sys_open!"
msg_err_mmap:     .asciz "[ASM abrir_memoria] ERRO na chamada sys_mmap2!"

msg_inst_start:   .asciz "\n[ASM enviar_instrucao] INICIO -> Instrucao: 0x%08X | Base: %p\n"
msg_wait_ready:   .asciz "[ASM enviar_instrucao] Passo 1: Lendo PIO_READY_BASE..."
msg_ready_ok:     .asciz "[ASM enviar_instrucao] Passo 2: READY==1! Gravando instrucao e ATIVA=1..."
msg_wait_valid1:  .asciz "[ASM enviar_instrucao] Passo 3: Aguardando PIO_VALID_BASE == 1..."
msg_valid1_ok:    .asciz "[ASM enviar_instrucao] Passo 4: VALID==1! Setando CLEAR=1 e ATIVA=0..."
msg_wait_valid0:  .asciz "[ASM enviar_instrucao] Passo 5: Aguardando PIO_VALID_BASE == 0..."
msg_valid0_ok:    .asciz "[ASM enviar_instrucao] Passo 6: VALID==0! Setando CLEAR=0..."
msg_inst_end:     .asciz "[ASM enviar_instrucao] Handshake concluido com SUCESSO!\n"

    .section .note.GNU-stack,"",%progbits