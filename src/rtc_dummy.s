/* =====================================================
   RTC Dummy – Seguro (não trava o terminal)
===================================================== */

.global .dummy_set_time
.global .dummy_print_time


.section .data
.align 4

.global dummy_hour
.global dummy_min
.global dummy_sec

dummy_hour: .byte 0
dummy_min:  .byte 0
dummy_sec:  .byte 0


.section .bss
.align 4
_rtc_hours:    .space 1
_rtc_minutes:  .space 1
_rtc_seconds:  .space 1
_ascii_buf:    .space 4      @ 2 dígitos + '\0'

.section .rodata
colon: .asciz ":"
CRLF:  .asciz "\n\r"

.section .text
.code 32
.align 4

/* -----------------------------
   set time  → 10:00:00
----------------------------- */
/* -----------------------------
   set time → 10:00:00
----------------------------- */
.global .dummy_set_time
.dummy_set_time:
    stmfd sp!, {r0-r2, lr}

    mov r1, #10
    ldr r0, =dummy_hour
    strb r1, [r0]

    mov r1, #0
    ldr r0, =dummy_min
    strb r1, [r0]

    ldr r0, =dummy_sec
    strb r1, [r0]

    ldmfd sp!, {r0-r2, pc}


/* -----------------------------
   time → HH:MM:SS
----------------------------- */
/* -----------------------------
   time → HH:MM:SS
----------------------------- */
.global .dummy_print_time

.section .text
.align 4

.dummy_print_time:
    stmfd sp!, {r0, lr}

    ldr r0, =dummy_time_str
    bl .print_string

    ldmfd sp!, {r0, pc}




/* -----------------------------
   byte (0–59) → "NN"
----------------------------- */
byte_to_ascii:
    stmfd sp!, {r1-r6, lr}

    ldr r0, =_ascii_buf

    mov r2, r1      @ valor (0–59)
    mov r4, #0      @ dezenas

.div_loop:
    cmp r2, #10
    blt .div_done
    sub r2, r2, #10
    add r4, r4, #1
    b .div_loop

.div_done:
    mov r5, r2      @ unidades

    add r4, r4, #'0'
    add r5, r5, #'0'

    strb r4, [r0]
    strb r5, [r0, #1]
    mov r6, #0
    strb r6, [r0, #2]

    ldmfd sp!, {r1-r6, pc}

.section .rodata
.align 4
dummy_time_str: .asciz "10:00:00\n\r"
