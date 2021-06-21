test {
    // TODO Walk paths to get zig files
    _ = @import("arch/aarch64/aarch64.zig");
    _ = @import("arch/aarch64/init.zig");
    _ = @import("arch/aarch64/mailbox.zig");
    _ = @import("arch/aarch64/mmio.zig");
    _ = @import("arch/aarch64/slice_iterator.zig");
    _ = @import("arch/aarch64/time.zig");
    _ = @import("arch/aarch64/uart.zig");

    _ = @import("arch/x86_64/init.zig");
    _ = @import("arch/x86_64/uart.zig");
    _ = @import("arch/x86_64/x86.zig");

    _ = @import("bootboot.zig");
}
