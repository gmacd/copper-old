const bb = @import("../../bootboot.zig");
const sys = @import("../../sys.zig");
const Serial = @import("Serial.zig");

const ArchSys = struct {
    sys: sys.Sys,
    // arch-specific
    serial: Serial,
};

var archSys: ArchSys = undefined;

pub fn init(bootboot: *bb.BootBootInfo) *sys.Sys {
    // Kernel stack
    // Need to set up a kernel stack.  In harvey we have a 16KiB stack with a stack guard, though
    // the stack guard isn't used.
    // To protect against buffer overflow on x86 we can set up a GDT descriptor for the stack.

    // Stack grows down from pointer in ESP, and should be 16 byte aligned (consistent across
    // aarch64, riscv64, x86-64).  Seems common to reserve area in BSS.
    archSys.sys.init();

    archSys.serial = Serial.init();
    archSys.sys.serial = &archSys.serial.serial;

    return &archSys.sys;
}
