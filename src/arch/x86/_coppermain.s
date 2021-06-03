.global _coppermain
.type _coppermain, @function

_coppermain:
    mov $0x80000, %esp  // Setup the stack.

    push %ebx   // Pass multiboot info structure.
    push %eax   // Pass multiboot magic code.

    call coppermain  // Call the kernel.

    // Halt the CPU.
    cli
    hlt