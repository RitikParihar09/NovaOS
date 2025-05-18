[bits 32]
[extern kernel_main]

section .text
global _start

_start:
    ; Call the kernel main function
    call kernel_main
    
    ; If kernel_main returns, halt the CPU
    jmp $
