pub const Serial = struct {
    printFn: fn (self: *Serial, str: []const u8) void,

    pub fn print(self: *Serial, str: []const u8) void {
        self.printFn(self, str);
    }
};
