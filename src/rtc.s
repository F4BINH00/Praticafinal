/* rtc.s – STUB */

.global RTC_BASE
.global .rtc_setup

.equ RTC_BASE, 0x44E3E000   @ mantém símbolo para utils.s

.section .text,"ax"
.align 4

.rtc_setup:
    bx lr   @ NÃO faz nada
