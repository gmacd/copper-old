const mem = @import("std").mem;
const x86 = @import("x86.zig");

pub const VGA_WIDTH  = 80;
pub const VGA_HEIGHT = 25;
pub const VGA_SIZE = VGA_WIDTH * VGA_HEIGHT;
pub const VGA_BUFFER_ADDR = 0xB8000;

const ASCII_BACKSPACE = 8;

/// VGA colour codes.  Some will map to blinking chars if applied to the BG.
pub const Colour = enum(u4) {
    Black        = 0,
    Blue         = 1,
    Green        = 2,
    Cyan         = 3,
    Red          = 4,
    Magenta      = 5,
    Brown        = 6,
    LightGrey    = 7,
    DarkGrey     = 8,
    LightBlue    = 9,
    LightGreen   = 10,
    LightCyan    = 11,
    LightRed     = 12,
    LightMagenta = 13,
    LightBrown   = 14,
    White        = 15,
};

pub const VgaChar = packed struct {
    char: u8,
    fg: Colour,
    bg: Colour,
};

pub const Vga = struct {
    buffer: []VgaChar,
    cursor: usize,
    fg: Colour,
    bg: Colour,

    pub fn init(bufferAddr: usize) Vga {
        var vga = Vga {
            .buffer = @intToPtr([*]VgaChar, bufferAddr)[0..0x4000],
            .cursor = 0,
            .fg = Colour.White,
            .bg = Colour.Black,
        };

        vga.clear();
        return vga;
    }

    pub fn clear(self: *Vga) void {
        mem.set(VgaChar, self.buffer[0..VGA_SIZE], self.char(' '));
        self.cursor = 0;
        self.updateCursor();
    }

    pub fn enableCursor() void {
        x86.outb(0x3D4, 0x0A);
        x86.outb(0x3D5, 0x00);
    }

    pub fn disableCursor() void {
        x86.outb(0x3D4, 0x0A);
        x86.outb(0x3D5, 1 << 5);
    }

    fn updateCursor(self: *const Vga) void {
        x86.outb(0x3D4, 0x0F);
        x86.outb(0x3D5, @truncate(u8, self.cursor));
        x86.outb(0x3D4, 0x0E);
        x86.outb(0x3D5, @truncate(u8, self.cursor >> 8));
    }

    fn scrollDown(self: *Vga) void {
        const first = VGA_WIDTH;
        const last  = VGA_SIZE - VGA_WIDTH;

        mem.copy(VgaChar, self.buffer[0..last], self.buffer[first..VGA_SIZE]);
        mem.set(VgaChar, self.buffer[last..VGA_SIZE], self.char(' '));

        // Bring the cursor back to the beginning of the last line.
        self.cursor -= VGA_WIDTH;
    }

    pub fn print(self: *Vga, str: []const u8) void {
        for (str) |c| {
            self.printChar(c);
        }
        self.updateCursor();
    }

    fn printChar(self: *Vga, c: u8) void {
        if (self.cursor == VGA_SIZE-1) {
            self.scrollDown();
        }
        switch (c) {
            '\n' => {
                self.printChar(' ');
                while ((self.cursor % VGA_WIDTH) != 0) {
                    self.printChar(' ');
                }
            },
            '\t' => {
                // 2 space tabs
                self.printChar(' ');
                while ((self.cursor % 2) != 0) {
                    self.printChar(' ');
                }
            },
            ASCII_BACKSPACE => {
                self.cursor -= 1;
                self.printChar(' ');
                self.cursor -= 1;
            },
            else => {
                self.buffer[self.cursor] = self.char(c);
                self.cursor += 1;
            },
        }
    }

    fn char(self: *Vga, c: u8) VgaChar {
        return VgaChar { .char = c, .fg = self.fg, .bg = self.bg, };
    }
};
