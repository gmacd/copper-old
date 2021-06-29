const builtin = @import("builtin");
const std = @import("std");
const bb = @import("bootboot.zig");
const screen = @import("screen.zig");
const Sys = @import("sys.zig").Sys;

const archPath = "arch/" ++ @tagName(builtin.cpu.arch);
const archInit = @import(archPath ++ "/init.zig");

extern var bootboot: bb.BootBootInfo;
extern var fb: [*]u8;

var sys: *Sys = undefined;

// TODO take log level from kernel args?
pub const log_level: std.log.Level = .debug;

// Define root.log to override the std implementation
pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const prefix = "[" ++ @tagName(level) ++ "] ";

    // TODO lock?
    sys.serial.print(prefix);

    var buf: [4]u8 = undefined;
    if (std.fmt.bufPrint(buf[0..], format, args)) |str| {
        sys.serial.print(str);
    } else |err| {
        sys.serial.print(" (Error formatting: '" ++ format ++ "' error: ");
        sys.serial.print(@errorName(err));
        sys.serial.print(")");
    }

    sys.serial.print("\n");
}

export fn _start() noreturn {
    sys = archInit.init(&bootboot);
    std.log.info("Copper {}", .{123});

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

    screen.print("X");

    while (true) {}
}
