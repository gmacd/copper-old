const Array = @import("std").ArrayList;
const Builder = @import("std").build.Builder;
const builtin = @import("builtin");
const CrossTarget = @import("std").zig.CrossTarget;
const Step = @import("std").build.Step;

const buildDir = "build";

pub fn build(b: *Builder) void {
    const kernelStep = buildKernelX86(b);
    const kernelOutputPath = buildKernelImageX86(b, kernelStep);
    qemuStep(b, kernelOutputPath);
}

fn buildKernelX86(b: *Builder) *Step {
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
    kernel.setOutputDir(buildDir ++ "/iso/boot");
    //kernel.setOutputDir("build/copperiso/boot");

    b.default_step.dependOn(&kernel.step);
    return &kernel.step;
}

fn buildKernelImageX86(b: *Builder, kernelStep: *Step) []const u8 {
    // Copying the grub cfg for the iso
    //b.installFile("src/arch/x86/boot/multiboot_grub.cfg", "build/copperiso/boot/grub.cfg");
    b.installFile("src/arch/x86/boot/multiboot_grub.cfg", "iso/boot/grub.cfg");

    // Make multiboot iso
    const mkiso = b.addSystemCommand(&[_][]const u8{ "grub-mkrescue", "-o", buildDir ++ "/copper.iso", buildDir ++ "/iso" });
    mkiso.step.dependOn(kernelStep);
    b.default_step.dependOn(&mkiso.step);

    return buildDir ++ "/copper.iso";
}

fn qemuStep(b: *Builder, imgPath: []const u8) void {
    const base_params = &[_][]const u8{ "qemu-system-x86_64", "-enable-kvm", "-serial", "stdio", "-kernel", imgPath };

    // qemu
    const qemu = b.step("qemu", "Run copper with qemu");
    var params = Array([]const u8).init(b.allocator);
    for (base_params) |p| {
        params.append(p) catch unreachable;
    }
    const run_qemu = b.addSystemCommand(params.items);
    run_qemu.step.dependOn(b.default_step);
    qemu.dependOn(&run_qemu.step);

    // qemu-debug
    const qemu_debug = b.step("qemu-debug", "Run copper with qemu and wait for debugger to attach");
    const debug_params = &[_][]const u8{ "-s", "-S" };
    for (debug_params) |p| {
        params.append(p) catch unreachable;
    }
    const run_qemu_debug = b.addSystemCommand(params.items);
    run_qemu_debug.step.dependOn(b.default_step);
    qemu_debug.dependOn(&run_qemu_debug.step);
}