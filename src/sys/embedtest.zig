const std = @import("std");

const embeddedFont = @embedFile("fonts/font.psf");

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

test "can embed font" {
    try std.testing.expectEqual(213, embeddedFont.len);
    //const font: *const PsFont = @ptrCast(*const PsFont, &embeddedFont);
    //const fontx = font.*;
    //try std.testing.expect(fontx.magic == 123);
}
