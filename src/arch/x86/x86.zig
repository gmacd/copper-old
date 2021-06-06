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

pub inline fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]" : [result] "={al}" (-> u8)
                                                  : [port]   "N{dx}" (port));
}

pub inline fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]" : : [value] "{al}" (value),
                                               [port]  "N{dx}" (port));
}