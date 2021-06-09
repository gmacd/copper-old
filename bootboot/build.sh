#!/bin/sh
rm -rf copper.img boot/

mkdir -p boot/aarch64/sys
mkdir -p boot/x86_64/sys
cp mykernel.aarch64.elf boot/aarch64/sys/copperkernel
#cp mykernel.x86_64.elf boot/x86_64/sys/copperkernel

cp ../build/copper boot/x86_64/sys/copperkernel

./mkbootimg copper-mkbootimg.json copper.img

rm -rf boot/

# qemu x86 bios
# qemu-system-x86_64 -drive file=copper.img,format=raw -serial stdio
# qemu x86 efi
# qemu-system-x86_64 -bios /usr/share/qemu/OVMF.fd -m 64 -drive file=copper.img,format=raw -serial stdio
# qemu x86 linux
# qemu-system-x86_64 -kernel bootboot.bin -drive file=copper.img,format=raw -serial stdio
# qemu aarch64
# qemu-system-aarch64 -M raspi3 -kernel bootboot-rpi.img -drive file=copper.img,if=sd,format=raw -serial stdio
