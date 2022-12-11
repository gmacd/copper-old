//! Basic screen functionality

const std = @import("std");
const BootBootInfo = @import("core").boot.BootBootInfo;

const embeddedFont = @embedFile("fonts/font.psf");

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

//var Font: *const PSFFont = @ptrCast(*const PSFFont, &FontEmbed);
//extern const _binary_assets_font_psf_start: u8;
extern var fb: [*]u8;
extern var bootboot: BootBootInfo;

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
    std.log.info("Copper {c} {d}", .{ '#', 567 });
    const font: *const PsFont = @ptrCast(*const PsFont, &embeddedFont);
    @compileLog("comptime font", @typeName(@TypeOf(font)), font.width);
    //    std.log.info("font w:{} h:", .{123});

    var kx: u32 = 0;
    var bpl = (font.width + 7) / 8;
    for (str) |c| {
        //std.log.info("2", .{});
        const glyphIdx = if (c > 0 and c < font.numGlyphs) c else 0;
        var glyph: *u32 = @intToPtr(*u32, (@ptrToInt(&embeddedFont) + font.headerSize + glyphIdx * font.bytesPerGlyph));
        var offs = kx * (font.width + 1) * 4;

        var y: u32 = 0;
        while (y < font.height) : (y += 1) {
            //std.log.info("3", .{});
            var line = offs;

            var mask: u32 = 1;
            mask <<= @intCast(u5, font.width - 1);
            //std.log.info("31", .{});

            var x: u32 = 0;
            while (x < font.width) : (x += 1) {
                //std.log.info("4", .{});
                var pixelPtr: *u32 = @intToPtr(*u32, @ptrToInt(&fb) + line);
                var maskval: u32 = if (mask > 0) 0xffffff else 0;
                pixelPtr.* = glyph.* & maskval;
                mask >>= 1;
                line += 4;
                //std.log.info("5", .{});
            }
            //std.log.info("6", .{});
            var pixelPtr: *u32 = @intToPtr(*u32, @ptrToInt(&fb) + line);
            pixelPtr.* = 0;
            //std.log.info("7", .{});
            glyph = @intToPtr(*u32, @ptrToInt(glyph) + bpl * @sizeOf(u32));
            //std.log.info("8", .{});
            offs += bootboot.fb_scanline;
            //std.log.info("9", .{});
        }
        kx += 1;
    }
}
