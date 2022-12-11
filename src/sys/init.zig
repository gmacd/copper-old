const builtin = @import("builtin");
const StackTrace = @import("std").builtin.StackTrace;
const std = @import("std");
const Sys = @import("core").sys.Sys;

extern var fb: [*]u8;

var sys: *Sys = undefined;

// TODO take log level from kernel args?
pub const log_level: std.log.Level = .debug;

// Define root.log to override the std implementation
pub fn log(
    comptime level: std.log.Level,
    comptime _: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const prefix = "[" ++ @tagName(level) ++ "] ";

    // TODO lock?
    sys.serial.print(prefix);

    var buf: [2048]u8 = undefined;
    if (std.fmt.bufPrint(buf[0..], format, args)) |str| {
        sys.serial.print(str);
        sys.serial.print("x\n");
    } else |err| {
        sys.serial.print(" (Error formatting: '" ++ format ++ "' error: ");
        sys.serial.print(@errorName(err));
        sys.serial.print(")\n");
    }
}

pub fn panic(msg: []const u8, _: ?*StackTrace) noreturn {
    sys.serial.print("===============================\n");
    sys.serial.print("Kernel Panic.  Guru Meditation.\n");
    sys.serial.print(msg);
    sys.serial.print("\n");
    // TODO Use halt instruction
    // TODO Dump stacktrace: https://andrewkelley.me/post/zig-stack-traces-kernel-panic-bare-bones-os.html
    while (true) {}
}
