const builtin = @import("builtin");
const StackTrace = @import("std").builtin.StackTrace;
const std = @import("std");
const BootBootInfo = @import("core").boot.BootBootInfo;
const Sys = @import("core").sys.Sys;
const arch = @import("arch");
const sys = @import("sys");
const screen = @import("sys/screen.zig");

extern var fb: [*]u8;
extern var bootboot: BootBootInfo;

var sysx: *Sys = undefined;

export fn kernelStart() void {
    sysx = arch.init(&bootboot);
    std.log.info("Copper {}", .{123});

    // TODO cpu timing setup

    // const s = bootboot.fb_scanline;
    // const w = bootboot.fb_width;
    // const h = bootboot.fb_height;

    // if (s > 0) {
    //     var y: usize = 0;
    //     while (y < h) {
    //         @intToPtr(*u32, @ptrToInt(&fb) + (s * y) + (w * 2)).* = 0x00ffffff;
    //         y += 1;
    //     }
    //     var x: usize = 0;
    //     while (x < w) {
    //         @intToPtr(*u32, @ptrToInt(&fb) + (s * (h / 2)) + (x * 4)).* = 0x00ffffff;
    //         x += 1;
    //     }

    //     y = 0;
    //     while (y < 20) {
    //         x = 0;
    //         while (x < 20) {
    //             @intToPtr(*u32, @ptrToInt(&fb) + (s * y + 20) + (x + 20) * 4).* = 0x00ff0000;
    //             x += 1;
    //         }
    //         y += 1;
    //     }
    // }

    screen.print("i");
}
