const builtin = @import("builtin");
const std = @import("std");
const assert = @import("std").debug.assert;
const bb = @import("bootboot.zig");
const screen = @import("screen.zig");
//const sys = @import("sys.zig");

const archPath = "arch/" ++ @tagName(builtin.cpu.arch);
const archInit = @import(archPath ++ "/init.zig");
const archSerial = @import(archPath ++ "/serial.zig");

extern var bootboot: bb.BootBootInfo;
extern var fb: [*]u8;

// TODO take log level from kernel args?
pub const log_level: std.log.Level = .debug;

// Define root.log to override the std implementation
pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    // Ignore all non-critical logging from sources other than
    // .my_project, .nice_library and .default
    // const scope_prefix = "(" ++ switch (scope) {
    //     .my_project, .nice_library, .default => @tagName(scope),
    //     else => if (@enumToInt(level) <= @enumToInt(std.log.Level.crit))
    //         @tagName(scope)
    //     else
    //         return,
    // } ++ "): ";

    //const prefix = "[" ++ @tagName(level) ++ "] " ++ scope_prefix;
    const prefix = "[" ++ @tagName(level) ++ "] ";

    // Print the message to stderr, silently ignoring any errors
    // const held = std.debug.getStderrMutex().acquire();
    // defer held.release();
    // const stderr = std.io.getStdErr().writer();
    // nosuspend stderr.print(prefix ++ format ++ "\n", args) catch return;

    //sys.serial.print("112233\n");
}

export fn _start() noreturn {
    //var archSerialXXX = archSerial.ArchSerial().init();
    //var serial: *sys.Serial = &archSerialXXX.serial;
    //serial.print("foobar");
    //std.log.info("hello", .{});

    var sys = archInit.init(&bootboot);
    sys.serial.print("foobar");

    const s = bootboot.fb_scanline;
    const w = bootboot.fb_width;
    const h = bootboot.fb_height;

    if (s > 0) {
        var y: usize = 0;
        while (y < h) {
            @intToPtr(*u32, @ptrToInt(&fb) + (s * y) + (w * 2)).* = 0x00ffffff;
            y += 1;
        }
        var x: usize = 0;
        while (x < w) {
            @intToPtr(*u32, @ptrToInt(&fb) + (s * (h / 2)) + (x * 4)).* = 0x00ffffff;
            x += 1;
        }

        y = 0;
        while (y < 20) {
            x = 0;
            while (x < 20) {
                @intToPtr(*u32, @ptrToInt(&fb) + (s * y + 20) + (x + 20) * 4).* = 0x00ff0000;
                x += 1;
            }
            y += 1;
        }
    }

    //  screen.print("hello from copperos");

    while (true) {}
}
