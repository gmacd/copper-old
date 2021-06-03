const multiboot = @import("multiboot.zig");
const x86 = @import("x86.zig");

//pub fn panic(message: []const u8, stack_trace: ?*@import("builtin").StackTrace) noreturn {
    //tty.panic("{}", message);
//}

export fn coppermain(magic: u32, info: *const multiboot.MultibootInfo) noreturn {
    // tty init
    //assert(magic == multiboot.MULTIBOOT_BOOTLOADER_MAGIC);
    x86.sti();
    x86.hlt();
}