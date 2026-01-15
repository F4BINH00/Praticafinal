/* Global Symbols */
.global RTC_BASE
.global .rtc_setup
.global .rtc_isr
.global .rtc_to_ascii
.global .uart_to_rtc
.global .print_time
.global .rtc_set_dummy_time

/* Registers */
.equ CM_RTC_RTC_CLKCTRL, 0x44E00800
.equ CM_RTC_CLKSTCTRL,   0x44E00804
.equ RTC_BASE, 0x44E3E000

/* Text Section */
.section .text,"ax"
         .code 32
         .align 4
         
/********************************************************
RTC SETUP 
********************************************************/
.rtc_setup:
    stmfd sp!,{r0-r1,lr}

    /* Clock enable for RTC */
    ldr r0, =CM_RTC_CLKSTCTRL
    ldr r1, =0x2
    str r1, [r0]
    ldr r0, =CM_RTC_RTC_CLKCTRL
    str r1, [r0]

    /* Disable write protection */
    ldr r0, =RTC_BASE
    ldr r1, =0x83E70B13
    str r1, [r0, #0x6c]
    ldr r1, =0x95A4F1E0
    str r1, [r0, #0x70]
    
    /* Select external clock */
    ldr r1, =0x48
    str r1, [r0, #0x54]

    /* Interrupt setup (Every Second) */
    @ ldr r1, =0x04     
    @ str r1, [r0, #0x48]

    /* Enable RTC (Bit 0 = 0 means RUN) */
    ldr r0, =RTC_BASE
    ldr r1, =(1<<0)
    str r1, [r0, #0x40]  

    /* Wait RTC update */
.wait_rtc_update:
    ldr r1, [r0, #0x44]
    and r1, r1, #1
    cmp r1, #0
    bne .wait_rtc_update

    /* INTC Setup */
    ldr r0, =INTC_ILR
    ldr r1, =#0    
    strb r1, [r0, #75] 

    ldr r0, =INTC_BASE
    ldr r1, =#(1<<11)    
    str r1, [r0, #0xc8] 

    ldmfd sp!,{r0-r1,pc}

/********************************************************
 RTC ISR - CORRIGIDA
********************************************************/
.rtc_isr:
    stmfd sp!, {r0-r2, lr}

    /* limpa RTC */
    ldr r0, =RTC_BASE
    mov r1, #1
    str r1, [r0, #0x44]

    /* EOI */
    ldr r0, =INTC_BASE
    mov r1, #1
    str r1, [r0, #0x48]

    ldmfd sp!, {r0-r2, lr}
    subs pc, lr, #4


/********************************************************
 Imprime hora
********************************************************/
.rtc_to_ascii:
    stmfd sp!,{r0-r2,lr} 
    mov r2, r0
    
    and r0, r2, #0x70
    mov r0, r0, LSR #4
    bl .dec_digit_to_ascii
    bl .uart_putc

    and r0, r2, #0x0f
    add r0,r0,#0x30 
    bl .uart_putc

    ldmfd sp!, {r0-r2, pc}

.print_time:
    stmfd sp!,{r0-r2,lr}
    ldr r1,=RTC_BASE
    
    ldr r0, [r1, #8] //hours
    bl .rtc_to_ascii
    ldr r0,=':'
    bl .uart_putc

    ldr r0, [r1, #4] //minutes
    bl .rtc_to_ascii
    ldr r0,=':'
    bl .uart_putc

    ldr r0, [r1, #0] //seconds
    bl .rtc_to_ascii

    ldr r0, =prox_linha
    bl .print_string
    ldmfd sp!, {r0-r2, pc}

/********************************************************
 Set Dummy Time 
********************************************************/
.rtc_set_dummy_time:
    push {r0-r2, lr}      @ Salva o contexto e o endereço de retorno

    ldr r0, =RTC_BASE     @ Endereço Base do RTC (0x44E3E000)

    @ 1. Destravar proteção (KICK registers)
    ldr r1, =0x83E70B13
    str r1, [r0, #0x6C] 
    ldr r1, =0x95A4F1E0
    str r1, [r0, #0x70] 

    @ 2. ESCREVER DIRETO (Sem verificar BUSY, sem STOP)
    @ Isso elimina qualquer chance de loop infinito aqui.
    
    mov r1, #0x00
    str r1, [r0, #0x00]   @ Segundos = 00
    str r1, [r0, #0x04]   @ Minutos  = 00
    
    mov r1, #0x12         
    str r1, [r0, #0x08]   @ Horas    = 12 (Vamos mudar pra 12h pra diferenciar)

    @ 3. (Opcional) Travar novamente ou deixar assim.
    @ O importante é que aqui não tem onde travar.

    pop {r0-r2, pc}       @ Retorna imediatamente

/* Helpers */
.uart_to_rtc:
    stmfd sp!, {r1-r5, lr}
    ldr r1,=RTC_BASE           
    and r5, r5, #0xffffff
    strb r5, [r1]
    mov r5, r5, lsr #8
    strb r5, [r1, #4]
    mov r5, r5, lsr #8
    strb r5, [r1, #8]
    ldmfd sp!, {r1-r5, pc}

prox_linha:    .asciz "\n\r"
