//! Basic screen functionality

const bb = @import("bootboot.zig");

//extern fn printx(s: []u8) void;

// typedef struct {
//     uint32_t magic;
//     uint32_t version;
//     uint32_t headersize;
//     uint32_t flags;
//     uint32_t numglyph;
//     uint32_t bytesperglyph;
//     uint32_t height;
//     uint32_t width;
//     uint8_t glyphs;
// } __attribute__((packed)) psf2_t;
// extern volatile unsigned char _binary_font_psf_start;

const PsFont = packed struct {
    magic: u32,
    version: u32,
    headerSize: u32,
    flags: u32,
    numGlyphs: u32,
    bytesPerGlyph: u32,
    height: u32,
    width: u32,
    glyphs: u8,
};

extern const _binary_assets_font_psf_start: u8;
extern var fb: [*]u8;
extern var bootboot: bb.BootBootInfo;

// void puts(char *s)
// {
//     psf2_t *font = (psf2_t*)&_binary_assets_font_psf_start;
//     int x,y,kx=0,line,mask,offs;
//     int bpl=(font->width+7)/8;
//     while(*s) {
//         unsigned char *glyph = (unsigned char*)&_binary_assets_font_psf_start + font->headersize +
//             (*s>0&&*s<font->numglyph?*s:0)*font->bytesperglyph;
//         offs = (kx * (font->width+1) * 4);
//         for(y=0;y<font->height;y++) {
//             line=offs; mask=1<<(font->width-1);
//             for(x=0;x<font->width;x++) {
//                 *((uint32_t*)((uint64_t)&fb+line))=((int)*glyph) & (mask)?0xFFFFFF:0;
//                 mask>>=1; line+=4;
//             }
//             *((uint32_t*)((uint64_t)&fb+line))=0; glyph+=bpl; offs+=bootboot.fb_scanline;
//         }
//         s++; kx++;
//     }
// }

pub fn print(str: []const u8) void {
    //printx("1\n");

    const font: *const PsFont = @ptrCast(*const PsFont, &_binary_assets_font_psf_start);
    var kx: u32 = 0;
    var bpl = (font.width + 7) / 8;
    for (str) |c| {
        const glyphIdx = if (c > 0 and c < font.numGlyphs) c else 0;
        var glyph: *u32 = @intToPtr(*u32, (@ptrToInt(&_binary_assets_font_psf_start) + font.headerSize + glyphIdx * font.bytesPerGlyph));
        var offs = kx * (font.width + 1) * 4;

        var y: u32 = 0;
        while (y < font.height) : (y += 1) {
            var line = offs;
            var one: u5 = 1;
            var fw: u3 = @intCast(u3, font.width);
            var mask: u32 = one << (fw);

            var x: u32 = 0;
            while (x < font.width) : (x += 1) {
                var pixelPtr: *u32 = @intToPtr(*u32, @ptrToInt(&fb) + line);
                //var maskval = 0;
                //if (mask > 0) {
                //    maskval = 0xffffff;
                //}
                var maskval: u32 = if (mask > 0) 0xffffff else 0;
                pixelPtr.* = glyph.* & maskval;
                mask >>= 1;
                line += 4;
            }
            var pixelPtr: *u32 = @intToPtr(*u32, @ptrToInt(&fb) + line);
            pixelPtr.* = 0;
            glyph = @intToPtr(*u32, @ptrToInt(glyph) + bpl);
            offs += bootboot.fb_scanline;
        }
        kx += 1;
    }
}
