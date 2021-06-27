const bb = @import("../../bootboot.zig");
const Sys = @import("../../sys.zig").Sys;
const Serial = @import("Serial.zig");

const ArchSys = struct {
    sys: Sys,
    // arch-specific
    serial: Serial,
};

var archSys: ArchSys = undefined;

pub fn init(bootboot: *bb.BootBootInfo) *Sys {
    archSys.serial = Serial.init();
    archSys.sys.serial = &archSys.serial.serial;

    return &archSys.sys;
}
