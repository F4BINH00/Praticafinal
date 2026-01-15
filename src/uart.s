/* Global Symbols */
.global .uart_putc
.global .uart_getc
.global .uart0_setup
.global .uart0
.global _buffer_count
.global _num_count
.global .limpar_buffer

/* Registradores */
.equ UART0_BASE, 0x44E09000
.equ UART0_IER, 0x44E09004

/* Text Section */
.section .text,"ax"
.code 32
.syntax unified
.align 4

/********************************************************
UART0 SETUP 
********************************************************/
.uart0_setup:
    stmfd sp!,{r0-r1,lr}
    
    /* Inicializa contadores com 0 */
    mov r2, #0
    ldr r3, =_buffer_count
    strb r2, [r3]
    ldr r3, =_num_count
    strb r2, [r3]

    /* Enable UART0 */
    ldr r0, =UART0_IER
    ldr r1, =#(1<<0) 
    strb r1, [r0]
    ldr r1, =#(1<<1) 
    strb r1, [r0]
    
    /* UART0 Interrupt configured as IRQ Priority 0 */
    ldr r0, =INTC_ILR
    ldr r1, =#0    
    strb r1, [r0, #72]
    
    /* Interrupt mask */
    ldr r0, =INTC_BASE
    ldr r1, =#(1<<8)    
    str r1, [r0, #0xc8] 
    
    ldmfd sp!,{r0-r1,pc}

/********************************************************
UART0 PUTC (Default configuration)  
********************************************************/
.align 4
.uart_putc:
    stmfd sp!,{r1-r2,lr}
    ldr     r1, =UART0_BASE

.wait_tx_fifo_empty:
    ldr r2, [r1, #0x14] 
    and r2, r2, #(1<<5)
    cmp r2, #0
    beq .wait_tx_fifo_empty

    strb    r0, [r1]
    ldmfd sp!,{r1-r2,pc}

/********************************************************
UART0 GETC (Default configuration)  
********************************************************/
.align 4
.uart_getc:
    stmfd sp!,{r1-r2,lr}
    ldr     r1, =UART0_BASE

.wait_rx_fifo:
    ldr r2, [r1, #0x14] 
    and r2, r2, #(1<<0)
    cmp r2, #0
    beq .wait_rx_fifo

    ldrb    r0, [r1]
    ldmfd sp!,{r1-r2,pc}

/********************************************************
UART0 - Lógica Principal
********************************************************/
.align 4
.uart0:
    stmfd sp!,{r0-r2,lr}     
    
    bl .uart_getc            @ Lê o caractere
    
    cmp r0, #'\r'            @ É um ENTER?
    beq .trata_enter         @ Se for, pula para tratar o comando
    
    @ --- Se NÃO for Enter (Letras/Números) ---
    bl .uart_putc            @ Ecoa o caractere na tela
    bl .save                 @ Salva no buffer
    b .fim_uart0             @ Termina

.align 4
.trata_enter:
    @ --- Se FOR Enter ---
    bl .uart0_comandos       @ Processa o comando
    @ Não chamamos .save aqui!

.align 4
.fim_uart0:
    ldmfd sp!,{r0-r2,pc}

/********************************************************
PROCESSADOR DE COMANDOS
********************************************************/
.align 4
.uart0_comandos:
    stmfd sp!,{r0-r4,lr}  @ Salva contexto

    ldr r0, =prox_linha
    bl .print_string
    
    @ --- 1. Verifica "hello" (5 chars) ---
    ldr r0, =comando1     
    ldr r1, =_buffer      
    mov r2, #5            
    bl .memcmp
    cmp r0, #0
    beq .exec_hello

    @ --- 2. Verifica "led on" (6 chars) ---
    ldr r0, =comando2
    ldr r1, =_buffer
    mov r2, #6
    bl .memcmp
    cmp r0, #0
    beq .exec_led_on

    @ --- 3. Verifica "led off" (7 chars) ---
    ldr r0, =comando3
    ldr r1, =_buffer
    mov r2, #7
    bl .memcmp
    cmp r0, #0
    beq .exec_led_off

    @ --- 4. Verifica "blink" (5 chars) ---
    ldr r0, =comando4
    ldr r1, =_buffer
    mov r2, #5
    bl .memcmp
    cmp r0, #0
    beq .exec_blink

    @ --- 5. Verifica "led" (3 chars) ---
    ldr r0, =comando5
    ldr r1, =_buffer
    mov r2, #3
    bl .memcmp
    cmp r0, #0
    beq .exec_led_generic

    @ --- 6. Verifica "time" (4 chars) ---
    ldr r0, =comando6
    ldr r1, =_buffer
    mov r2, #4
    bl .memcmp
    cmp r0, #0
    beq .exec_time

    @ --- 7. Verifica "set time" (8 chars) ---
    ldr r0, =comando7
    ldr r1, =_buffer
    mov r2, #8
    bl .memcmp
    cmp r0, #0
    beq .exec_set_time

    @ --- 8. Verifica "cache" (5 chars) ---
    ldr r0, =comando8
    ldr r1, =_buffer
    mov r2, #5
    bl .memcmp
    cmp r0, #0
    beq .exec_cache

    @ --- 9. Verifica "goto" (4 chars) ---
    ldr r0, =comando9
    ldr r1, =_buffer
    mov r2, #4
    bl .memcmp
    cmp r0, #0
    beq .exec_goto

    @ --- 10. Verifica "reset" (5 chars) ---
    ldr r0, =comando10
    ldr r1, =_buffer
    mov r2, #5
    bl .memcmp
    cmp r0, #0
    beq .exec_reset

    @ --- Comando não reconhecido ---
    ldr r0, =msg_unknown
    bl .print_string
    b .fim_comandos_label

/****************** HANDLERS *******************/
.align 4
.exec_hello:
    ldr r0, =hello
    bl .print_string
    b .fim_comandos_label

.align 4
.exec_led_on:
    bl .led_ON
    b .fim_comandos_label

.align 4
.exec_led_off:
    bl .led_OFF
    b .fim_comandos_label

.align 4
.exec_blink:
    mov r0, #5
    bl .blink_led
    b .fim_comandos_label

.align 4
.exec_led_generic:
    bl .led_ON
    b .fim_comandos_label

.align 4
.exec_set_time:
    bl .dummy_set_time
    ldr r0, =msg_time_set
    bl .print_string
    b .fim_comandos_label

.align 4
.exec_time:
    bl .dummy_print_time
    b .fim_comandos_label




.align 4
.exec_cache:
    bl .cp15_invalidate_icache
    ldr r0, =msg_cache
    bl .print_string
    b .fim_comandos_label

.align 4
.exec_goto:
    ldr r0, =msg_goto
    bl .print_string
    bl .limpar_buffer
    ldr r0, =0x80000000
    bx r0

.align 4
.exec_reset:
    b .reset

.align 4
.fim_comandos_label:

    @ === LIMPA CONTEÚDO DO BUFFER ===
    ldr r0, =_buffer
    mov r1, #0
    mov r2, #BUFFER_SIZE

.clear_loop:
    strb r1, [r0], #1
    subs r2, r2, #1
    bne .clear_loop

    @ === ZERA CONTADOR DO BUFFER ===
    ldr r0, =_buffer_count
    mov r1, #0
    strb r1, [r0]

    ldmfd sp!, {r0-r4, pc}   @ <<< RETORNA CORRETAMENTE




.align 4
.limpar_buffer:
    ldr r3, =_buffer_count
    mov r1, #0
    strb r1, [r3]
    ldr r3, =_num_count
    mov r1, #0
    strb r1, [r3]
    bx lr

.align 4
.save:
    stmfd sp!,{r1-r3,lr}
    ldr r3, =_buffer_count
    ldrb r2, [r3]
    cmp r2, #15
    bge .fim_save_real
    ldr r1, =_buffer
    strb r0, [r1, r2]
    add r2, r2, #1
    strb r2, [r3]

.align 4
.fim_save_real:
    ldmfd sp!,{r1-r3,pc}

/****************** STRINGS *******************/
.align 4
hello:         .asciz "Hello world!!!\n\r"
msg_time_set:  .asciz "Hora ajustada para 10:00:00\n\r"
msg_cache:     .asciz "Cache invalidado.\n\r"
msg_goto:      .asciz "Pulando para 0x80000000...\n\r"
msg_unknown:   .asciz "Comando desconhecido\n\r"
prox_linha:    .asciz "\n\r"
msg_time_not_set: .asciz "Hora ainda não ajustada! Use set time\n\r"

.align 4
comando1:      .asciz "hello"
comando2:      .asciz "led on"
comando3:      .asciz "led off"
comando4:      .asciz "blink"
comando5:      .asciz "led"
comando6:      .asciz "time"
comando7:      .asciz "set time"
comando8:      .asciz "cache"
comando9:      .asciz "goto"
comando10:     .asciz "reset"



/* BSS Section */
.section .bss
.align 4
.equ BUFFER_SIZE, 16
_num: .fill BUFFER_SIZE
_num_count: .fill 4
_buffer: .fill BUFFER_SIZE
_buffer_count: .fill 4
