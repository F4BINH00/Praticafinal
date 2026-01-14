/* Global Symbols */
.global .cp15_configure
.global .cp15_invalidate_icache
.type .cp15_configure, %function
.type .cp15_invalidate_icache, %function

/* Text Section */
.section .text,"ax"
         .code 32
         .align 4
         
/********************************************************
CP15 CONFIGURE
Configura vetor de interrupções (VBAR)
********************************************************/
.cp15_configure:
    stmfd sp!,{r0-r2,lr}

    /* Set V=0 in CP15 SCTRL register - for VBAR to point to vector */
    mrc     p15, 0, r0, c1, c0, 0   // Read CP15 SCTRL Register
    bic     r0, #(1 << 13)          // V = 0
    mcr     p15, 0, r0, c1, c0, 0   // Write CP15 SCTRL Register

    /* Set vector address in CP15 VBAR register */
    ldr     r0, =_vector_table
    mcr     p15, 0, r0, c12, c0, 0  // Set VBAR */

    ldmfd sp!,{r0-r2,pc}

/********************************************************
 Invalida Cache de Instruções
********************************************************/
.cp15_invalidate_icache:
    mov r0, #0
    /* MCR p15, 0, <Rd>, c7, c5, 0 -> Invalidate I-Cache */
    mcr p15, 0, r0, c7, c5, 0
    
    /* Pequena barreira para garantir (Instruction Sync Barrier) */
    mov r0, #0
    mcr p15, 0, r0, c7, c5, 4
    
    bx lr
