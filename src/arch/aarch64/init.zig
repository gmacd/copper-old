const bb = @import("../../bootboot.zig");
const mmio = @import("mmio.zig");
const uart = @import("uart.zig");

pub fn init(bootboot: bb.BootBootInfo) void {
    // mmio.init(bootboot);
    // const serial = uart.Serial.init();
    // serial.initPreInterrupt();
    // serial.print("fooooo\nxxx");
}
