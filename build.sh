#!/bin/sh
#rm -rf copper.img boot/

mkdir -p zig-out/boot/aarch64/sys
mkdir -p zig-out/boot/x86_64/sys

cp zig-out/copper.x86_64 zig-out/boot/x86_64/sys/copperkernel
cp zig-out/copper.aarch64 zig-out/boot/aarch64/sys/copperkernel
cp bootboot/config zig-out/config

cd zig-out && ../bootboot/mkbootimg ../bootboot/copper-mkbootimg.json copper.img

#rm -rf boot/

# qemu x86 bios
# qemu-system-x86_64 -drive file=zig-out/copper.img,format=raw -serial stdio
# qemu x86 efi
# qemu-system-x86_64 -bios /usr/share/qemu/OVMF.fd -m 64 -drive file=zig-out/copper.img,format=raw -serial stdio
# qemu x86 linux
# qemu-system-x86_64 -kernel bootboot.bin -drive file=zig-out/copper.img,format=raw -serial stdio
# qemu aarch64
# qemu-system-aarch64 -M raspi3 -kernel bootboot/bootboot-rpi.img -drive file=zig-out/copper.img,if=sd,format=raw -serial stdio
