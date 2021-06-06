const multiboot = @import("multiboot.zig");
const vga = @import("vga.zig");
const x86 = @import("x86.zig");

//pub fn panic(message: []const u8, stack_trace: ?*@import("builtin").StackTrace) noreturn {
    //tty.panic("{}", message);
//}

export fn coppermain(magic: u32, info: *const multiboot.MultibootInfo) noreturn {
    var vgazzz = vga.Vga.init(vga.VGA_BUFFER_ADDR);
    //assert(magic == multiboot.MULTIBOOT_BOOTLOADER_MAGIC);

    vgazzz.print("copper!");
    x86.sti();
    x86.hlt();
}