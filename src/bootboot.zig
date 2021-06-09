// mmap entry, type is stored in least significant tetrad (half byte) of size
// this means size described in 16 byte units (not a problem, most modern
// firmware report memory in pages, 4096 byte units anyway). */
pub const MMapEnt = packed struct {
    ptr: u64,
    size: u64,
};

pub const BootBootInfo = packed struct {
    // first 64 bytes is platform independent
    magic: [4]u8, // 'BOOT' magic
    size: u32, // length of bootboot structure, minimum 128
    protocol: u8, // 1, static addresses, see PROTOCOL_* and LOADER_* above
    fb_type: u8, // framebuffer type, see FB_* above
    numcores: u16, // number of processor cores
    bspid: u16, // Bootsrap processor ID (Local APIC Id on x86_64)
    timezone: i16, // in minutes -1440..1440
    datetime: [8]u8, // in BCD yyyymmddhhiiss UTC (independent to timezone)
    initrd_ptr: u64, // ramdisk image position and size
    initrd_size: u64,
    fb_ptr: u64, // framebuffer pointer and dimensions
    fb_size: u32,
    fb_width: u32,
    fb_height: u32,
    fb_scanline: u32,

    // the rest (64 bytes) is platform specific
    arch: packed union {
        x86_64: packed struct {
            acpi_ptr: u64,
            smbi_ptr: u64,
            efi_ptr: u64,
            mp_ptr: u64,
            unused0: u64,
            unused1: u64,
            unused2: u64,
            unused3: u64,
        },
        aarch64: packed struct {
            acpi_ptr: u64,
            mmio_ptr: u64,
            efi_ptr: u64,
            unused0: u64,
            unused1: u64,
            unused2: u64,
            unused3: u64,
            unused4: u64,
        },
    },

    // from 128th byte, MMapEnt[], more records may follow
    mmap: MMapEnt,
    // use like this:
    // MMapEnt *mmap_ent = &bootboot.mmap; mmap_ent++;
    // until you reach bootboot->size
};
