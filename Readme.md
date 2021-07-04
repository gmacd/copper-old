# Copper OS

Microkernel with wasm runtime.

## Build

To build an image that can be run in qemu, run this:
`zig build && ./buildimg.sh`

This builds a cross-platform image that can be run on x86-64 (bios or uefi) and aarch64 (raspi3+).

To run:
- qemu, x86-64, legacy bios: `qemu-system-x86_64 -drive file=zig-out/copper.img,format=raw -serial stdio --no-reboot`
- qemu, x86-64, uefi: `qemu-system-x86_64 -bios /usr/share/qemu/OVMF.fd -m 64 -drive file=zig-out/copper.img,format=raw -serial stdio`
- qemu, x86-64, qemu linux kernel mode: `qemu-system-x86_64 -kernel bootboot.bin -drive file=zig-out/copper.img,format=raw -serial stdio`
- qemu, aarch64, raspi3: `qemu-system-aarch64 -M raspi3 -kernel bootboot/bootboot-rpi.img -drive file=zig-out/copper.img,if=sd,format=raw -serial stdio`

## TODO
- use @embedFile instead of ld for font
- look up clashos tty reload feature
- more kernel code into 'kernel' subfolder
- set up stack
- ensure red-zone disabled

### Immediate
1. Set up write-only serial port
  1. Logging that uses serial initially
  2. Raspi3 serial
  3. Read https://scattered-thoughts.net/writing/mmio-in-zig/
2. Wrap up bootboot interface
2. Add simple logging framework (std.log)
2. Write up a blog post once we have screen and serial logging working on both arches
2. Start building sys object with serial, wrapped bootboot stuff, etc
3. Add panic function
4. Add stacktrace: https://github.com/andrewrk/clashos/blob/8ca226eb088d2a29f9a4875fd1245abb9842940b/src/debug.zig
5. Set up basic interrupts
6. Kernel allocator
  1. Get something braindead working first

### Longer Term
- Move buildimg.sh functionality into build.zig
- Boot on riscv64
- Replace bootboot with own bootloader
- Allow massive concurrency, fast messaging
- Load previous version of images at startup.  Timeline
- Debugger is essential.  OS level, eary
- Use imgui
- Write 10 things about it and come up with 20 examples: https://www.quora.com/What-does-Alan-Kay-think-about-the-following-research-proposal-notes-about-a-new-software-world-https-osoco-es-thoughts-2020-06-notes-about-a-new-software-world
- use nile for scalable graphics
- run it on a raspi 400, or riscv machine.  better chance of building a community

### 10 Things
1. Build a system that gives direct access to as much as possible.  Based on permission, allow them to modify and replace any part of the system.  Editor and debugger should always be part of the system.
2. System should be cross platform from the start.  x86 and aarch64 initially, then riscv64.  64 bit only.  Apart from kernel, rest of system should be wasm (or some other bytecode).
3. It should be very easy to create good graphical UIs.  Shouldn't need to resort to TUIs.
4. Everything (system state and user state) should be undoable, with branches.  Log-based filesystem?
5. Always keep checkpointed versions of the core system available in case user breaks something.  Should always be able to recover the system.
6. Use some sort of distributed ID for login
7. Use git behind the scenes to checkpoint changes to the source (need one repo for main system).  Commit automatically on successful recompile, periodically push to upstream.

## Random Thoughts...
- Are mailboxes a good analogy for IPC?  See zen kernel
- Would be good to get hundred rabbits code running eventually: https://twitter.com/hundredrabbits/status/1405198334881452033

Can use BOOTBOOT as the boot loader.  If the boot partition (FAT32) is split like:
- BOOTBOOT/X86_64
- BOOTBOOT/AARCH64
- BOOTBOOT/RISCV64
We can have a cross platform image.  The qemu image could cross compile all 3 builds at once.  Zig should allow us to do this fairly quickly, and ensure the builds stay in sync.

The image can contain other files/drivers that can be loaded by the boot loader.  This would help with microkernels.  Should be able to pack it all in a FAT32 partition.  This would make it easier to update.

BOOTBOOT/CONFIG stores the config vars.

Everything other than the kernel should be bytecode (wasm).  Ideally  we shuld be able to edit it live, like with smalltalk, but I have not idea how to do that.  The wasm should be JIT'ed when loaded.  Could have a cache for recently used programs.
