const bb = @import("../../bootboot.zig");
const uart = @import("uart.zig");

pub fn init(bootboot: bb.BootBootInfo) void {
    const serial = uart.Serial.init();
    serial.initPreInterrupt();
    serial.print("fooooo\nxxx");
}
