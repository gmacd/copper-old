/// Loop <delay> times in a way that the compiler won't optimize away
pub fn delay(count: usize) void {
    var i: usize = 0;
    while (i < count) : (i += 1) {
        asm volatile ("mov w0, w0");
    }
}

/// Datasynchronization barrier
pub fn dsb() void {
    asm volatile ("dsb st");
}
