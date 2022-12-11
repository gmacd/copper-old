const builtin = @import("builtin");
const std = @import("std");
const Array = std.ArrayList;
const Builder = std.build.Builder;
const FileSource = std.build.FileSource;
const CrossTarget = std.zig.CrossTarget;
const Arch = std.Target.Cpu.Arch;
const Step = std.build.Step;
const fs = std.fs;
const print = @import("std").debug.print;

const info = std.log.info;

const buildDir = "zig-out";

pub fn build(b: *Builder) void {
    print("zig version {}\n", .{builtin.zig_version});

    //const kernelStepX86 = buildKernel(b, Arch.x86_64);
    const kernelStepAarch64 = buildKernel(b, Arch.aarch64);
    _ = kernelStepAarch64;
    //_ = kernelStepAarch64;
    //const kernelOutputPath = buildKernelImage(b, kernelStepX86, kernelStepAarch64);
    //qemuStep(b, kernelOutputPath);
}

// TODO Make core pkg that arches can depend on and call into.
// Maybe put interfaces there?

/// Build the kernel for the given architecture
fn buildKernel(b: *Builder, comptime arch: Arch) *Step {

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const buildMode = b.standardReleaseOptions();
    const target = CrossTarget{ .cpu_arch = arch, .os_tag = .freestanding, .abi = .eabihf };

    // Build kernel
    const linkerSource = FileSource{ .path = "src/linker.ld" };
    const kernel = b.addExecutable("copper." ++ @tagName(arch), "src/main.zig");

    const corePkg = std.build.Pkg{
        .name = "core",
        .source = .{ .path = "src/core/core.zig" },
        .dependencies = &[_]std.build.Pkg{},
    };
    const archPkg = std.build.Pkg{
        .name = "arch",
        .source = .{ .path = "src/arch/" ++ @tagName(arch) ++ "/init.zig" },
        .dependencies = &[_]std.build.Pkg{corePkg},
    };
    const sysPkg = std.build.Pkg{
        .name = "sys",
        .source = .{ .path = "src/sys/init.zig" },
        .dependencies = &[_]std.build.Pkg{},
    };

    kernel.addPackage(corePkg);
    kernel.addPackage(archPkg);
    kernel.addPackage(sysPkg);
    
    kernel.addAssemblyFile("src/arch/" ++ @tagName(arch) ++ "/_start.s");
    kernel.setBuildMode(buildMode);
    kernel.setTarget(target);
    kernel.setLinkerScriptPath(linkerSource);
    kernel.setOutputDir(buildDir);

    b.default_step.dependOn(&kernel.step);

    // const lldTargetEmulation = switch (arch) {
    //     Arch.x86_64 => "elf_x86_64",
    //     Arch.aarch64 => "aarch64elf",
    //     else => unreachable,
    // };

    // // Convert font to object file
    // const build_font = b.addSystemCommand(&[_][]const u8{
    //     //"ld.lld", "-r", "-b", "binary", "-o", "font.o", "assets/font.psf",
    //     "ld", "-m", lldTargetEmulation, "-z", "noexecstack", "-r", "-b", "binary", "-o", buildDir ++ "/font.o", "assets/font.psf",
    // });
    // kernel.step.dependOn(&build_font.step);

    return &kernel.step;
}

// Build a bootboot-based image containing both x86_64 and aarch64 kernels
// fn buildKernelImage(b: *Builder, kernelStepX86: *Step, kernelStepAarch64: *Step) []const u8 {
//     b.installFile("build/copper.x86_64", "build/boot/x86_64/sys/copperkernel");
//     b.installFile("build/copper.aarch64", "build/boot/aarch64/sys/copperkernel");
//     b.installFile("bootboot/config", "config");

//     const cwdpath: []u8 = fs.cwd().realpathAlloc(b.allocator, "zig-out") catch "";
//     print("cwd:{s}\n", .{cwdpath});
//     const mkimg = b.addSystemCommand(&[_][]const u8{ "../bootboot/mkbootimg", "../bootboot/copper-mkbootimg.json", "copper.img" });
//     mkimg.cwd = cwdpath;
//     b.getInstallStep().dependOn(&mkimg.step);

//     // const mkiso = b.addSystemCommand(&[_][]const u8{ "grub-mkrescue", "-o", buildDir ++ "/copper.iso", buildDir ++ "/iso" });

//     return "";

//     // Copying the grub cfg for the iso
//     //b.installFile("src/arch/x86/boot/multiboot_grub.cfg", "build/copperiso/boot/grub.cfg");
//     // b.installFile("src/arch/x86/boot/multiboot_grub.cfg", "iso/boot/grub.cfg");

//     // // Make multiboot iso
//     // const mkiso = b.addSystemCommand(&[_][]const u8{ "grub-mkrescue", "-o", buildDir ++ "/copper.iso", buildDir ++ "/iso" });
//     // mkiso.step.dependOn(kernelStep);
//     // b.default_step.dependOn(&mkiso.step);

//     // return buildDir ++ "/copper.iso";
// }

// fn qemuStep(b: *Builder, imgPath: []const u8) void {
//     const base_params = &[_][]const u8{ "qemu-system-x86_64", "-enable-kvm", "-serial", "stdio", "-kernel", imgPath };

//     // qemu
//     const qemu = b.step("qemu", "Run copper with qemu");
//     var params = Array([]const u8).init(b.allocator);
//     for (base_params) |p| {
//         params.append(p) catch unreachable;
//     }
//     const run_qemu = b.addSystemCommand(params.items);
//     run_qemu.step.dependOn(b.default_step);
//     qemu.dependOn(&run_qemu.step);

//     // qemu-debug
//     const qemu_debug = b.step("qemu-debug", "Run copper with qemu and wait for debugger to attach");
//     const debug_params = &[_][]const u8{ "-s", "-S" };
//     for (debug_params) |p| {
//         params.append(p) catch unreachable;
//     }
//     const run_qemu_debug = b.addSystemCommand(params.items);
//     run_qemu_debug.step.dependOn(b.default_step);
//     qemu_debug.dependOn(&run_qemu_debug.step);
// }
