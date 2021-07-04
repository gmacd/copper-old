.global _start
.type _start, @function

// First subroutine to be called by the bootloader.
_start:
    // Set up the initial stack
    // TODO get end of stack from zig
    movabsq $initial_stack, %rax
    addq    $4096, %rax
    movq    %rax, %rsp

    call    kernelStart

    // Halt the CPU.
    cli
    hlt
