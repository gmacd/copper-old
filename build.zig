const Array = @import("std").ArrayList;
const Builder = @import("std").build.Builder;
const builtin = @import("builtin");
const CrossTarget = @import("std").zig.CrossTarget;

pub fn build(b: *Builder) void {
    const kernelOutputPath = buildKernelX86(b);

    const qemu = b.step("qemu", "Run the copper with qemu");
    const qemu_debug = b.step("qemu-debug", "Run copper with qemu and wait for debugger to attach");

    const common_params = &[_][]const u8 {
        "qemu-system-i386",
        "-kernel", kernelOutputPath,
    };
    const debug_params = &[_][]const u8 {"-s", "-S"};

    var qemu_params = Array([]const u8).init(b.allocator);
    var qemu_debug_params = Array([]const u8).init(b.allocator);
    for (common_params) |p| { qemu_params.append(p) catch unreachable; qemu_debug_params.append(p) catch unreachable; }
    for (debug_params) |p| { qemu_debug_params.append(p) catch unreachable; }

    const run_qemu = b.addSystemCommand(qemu_params.items);
    const run_qemu_debug = b.addSystemCommand(qemu_debug_params.items);

    run_qemu.step.dependOn(b.default_step);
    run_qemu_debug.step.dependOn(b.default_step);
    qemu.dependOn(&run_qemu.step);
    qemu_debug.dependOn(&run_qemu_debug.step);
}

fn buildKernelX86(b: *Builder) []const u8 {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const buildMode = b.standardReleaseOptions();
    const target = CrossTarget{ .cpu_arch = .i386, .os_tag = .freestanding, .abi = .none };

    const kernel = b.addExecutable("copper", "src/arch/x86/main.zig");

    kernel.addAssemblyFile("src/arch/x86/_coppermain.s");
    kernel.setBuildMode(buildMode);
    kernel.setTarget(target);
    kernel.setLinkerScriptPath("src/arch/x86/linker.ld");

    // Putting in copperiso/boot so that it can be built into a multiboot iso for qemu
    kernel.setOutputDir("zig-cache/iso/boot");
    //kernel.setOutputDir("build/copperiso/boot");
    // Copying the grub cfg for the iso
    //b.installFile("src/arch/x86/boot/multiboot_grub.cfg", "build/copperiso/boot/grub.cfg");
    b.installFile("src/arch/x86/boot/multiboot_grub.cfg", "iso/boot/grub.cfg");

    // Make multiboot iso
    const mkiso = b.addSystemCommand(&[_][]const u8 {"grub-mkrescue", "-o", "zig-cache/copper.iso", "zig-cache/iso"});
    kernel.step.dependOn(&mkiso.step);

    b.default_step.dependOn(&kernel.step);
    return "zig-cache/copper.iso";
}
