const bb = @import("../../bootboot.zig");
const mmio = @import("mmio.zig");
const Sys = @import("../../sys.zig").Sys;
const Serial = @import("serial.zig").Serial;

const ArchSys = struct {
    sys: Sys,
    // arch-specific
    serial: Serial,
};

var archSys: ArchSys = undefined;

pub fn init(bootboot: *bb.BootBootInfo) *Sys {
    mmio.init(bootboot);
    // const serial = uart.Serial.init();
    // serial.initPreInterrupt();
    // serial.print("fooooo\nxxx");

    archSys.serial = Serial.init();
    archSys.sys.serial = &archSys.serial.serial;

    return &archSys.sys;
}
