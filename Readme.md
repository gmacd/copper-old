Copper OS

Microkernel with wasm runtime.

Can use BOOTBOOT as the boot loader.  If the boot partition (FAT32) is split like:
- BOOTBOOT/X86_64
- BOOTBOOT/AARCH64
- BOOTBOOT/RISCV64
We can have a cross platform image.  The qemu image could cross compile all 3 builds at once.  Zig should allow us to do this fairly quickly, and ensure the builds stay in sync.

The image can contain other files/drivers that can be loaded by the boot loader.  This would help with microkernels.  Should be able to pack it all in a FAT32 partition.  This would make it easier to update.

BOOTBOOT/CONFIG stores the config vars.

Everything other than the kernel should be bytecode (wasm).  Ideally  we shuld be able to edit it live, like with smalltalk, but I have not idea how to do that.

