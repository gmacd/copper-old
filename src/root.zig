const std = @import("std");

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

    sys.serial.print("112233\n");
}
