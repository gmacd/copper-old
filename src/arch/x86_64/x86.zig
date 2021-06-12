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

/// Read a byte from a port
pub inline fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]"
        : [result] "={al}" (-> u8)
        : [port] "N{dx}" (port)
    );
}

/// Read 2 bytes from a port
pub inline fn inw(port: u16) u16 {
    return asm volatile ("inw %[port], %[result]"
        : [result] "={ax}" (-> u16)
        : [port] "N{dx}" (port)
    );
}

/// Read 4 bytes from a port
pub inline fn inl(port: u16) u32 {
    return asm volatile ("inl %[port], %[result]"
        : [result] "={eax}" (-> u32)
        : [port] "N{dx}" (port)
    );
}

/// Write a byte to a port
pub inline fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]"
        :
        : [value] "{al}" (value),
          [port] "N{dx}" (port)
    );
}

/// Write 2 bytes to a port
pub inline fn outw(port: u16, value: u16) void {
    asm volatile ("outw %[value], %[port]"
        :
        : [value] "{ax}" (value),
          [port] "N{dx}" (port)
    );
}

/// Write 4 bytes to a port
pub inline fn outl(port: u16, value: u32) void {
    asm volatile ("outl %[value], %[port]"
        :
        : [value] "{eax}" (value),
          [port] "N{dx}" (port)
    );
}
