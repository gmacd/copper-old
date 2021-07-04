pub const Serial = struct {
    printFn: fn (self: *Serial, str: []const u8) void,

    pub fn print(self: *Serial, str: []const u8) void {
        self.printFn(self, str);
    }
};

// Aarch64, riscv64, x86-64 all have 16 byte aligned stacks, so
// let's just declare it here.  It'll be in BSS.
pub export const INITIAL_STACK_SIZE = 10000;
pub export var initial_stack: [INITIAL_STACK_SIZE]u8 align(16) = undefined;

pub const Sys = struct {
    stack: *align(16) [INITIAL_STACK_SIZE]u8,
    serial: *Serial,

    pub fn init(self: *Sys) void {
        self.stack = &initial_stack;

        // TODO clear BSS?
    }
};
