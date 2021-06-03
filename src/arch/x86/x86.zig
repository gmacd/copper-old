/// Halt the CPU
pub inline fn hlt() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

/// Disable interrupts
pub inline fn cli() void {
    asm volatile ("cli");
}

/// Enable interrupts
pub inline fn sti() void {
    asm volatile ("sti");
}
