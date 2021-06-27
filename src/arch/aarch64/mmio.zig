//! Raspberry Pi MMIO (Only 3 and above supported)
//! I have no idea how applicable this is for other aarch64 systems.

const bb = @import("../../bootboot.zig");
const atomic = @import("std").atomic;

const Raspi = enum {
    Raspi3,
    Raspi4,
};

var mmioBase: u64 = 0;

pub fn init(bootboot: bb.BootBootInfo) void {
    // TODO how do we know what kind of raspi this is?
    // Let's go for raspi3 for now, since that's what qemu supports on my machine.
    const raspi = Raspi.Raspi3;
    mmioBase = switch (raspi) {
        .Raspi3 => 0x3f000000,
        .Raspi4 => 0xfe000000,
    };
    //TODO is this right?  bootboot gives me something else....

    // mmioBase = bootboot.arch.aarch64.mmio_ptr;
}

/// Write to reg as an offset from mmioBase
pub fn write(reg: usize, data: u32) void {
    @fence(atomic.Ordering.SeqCst);
    @intToPtr(*volatile u32, mmioBase + reg).* = data;
}

pub fn read(reg: usize) u32 {
    @fence(atomic.Ordering.SeqCst);
    return @intToPtr(*volatile u32, mmioBase + reg).*;
}
