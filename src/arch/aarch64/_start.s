
.globl _start
//.type _start, @function

_start:
    // Set up the initial stack
    // TODO get end of stack from zig
	ldr	x5, =initial_stack
	add	x5, x5, #4096
	mov	sp, x5


	// TODO get end of stack from zig
	bl	kernelStart

	// halt the cpu
hang:
	wfe
	b hang