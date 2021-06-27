const bb = @import("../../bootboot.zig");
const uart = @import("serial.zig");

pub fn init(bootboot: bb.BootBootInfo) void {
    uart.serial = uart.Serial.init();
    serial.initPreInterrupt();
    serial.print("fooooo\nxxx");
}
