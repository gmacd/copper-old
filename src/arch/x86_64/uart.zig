//! Uart provides functions to allow writing to the serial port at
//! as early a stage as possible.
//! When writing to the serial port before interrupts are enabled, the data
//! being written will block until complete.  This should only be enabled when
//! necessary.

const x86 = @import("x86.zig");

pub const COM1 = 0x3f8;
pub const COM2 = 0x2f8;
pub const COM3 = 0x3e8;
pub const COM4 = 0x2e8;

const DATA_REGISTER_OFFSET = 0;
const INTERRUPT_ENABLE_REGISTER_OFFSET = 1;
const DIVISOR_LSB_OFFSET = 0;
const DIVISOR_MSB_OFFSET = 1;
const INTERRUPT_FIFO_REGISTER_OFFSET = 2;
const LINE_CONTROL_REGISTER_OFFSET = 3;
const MODEM_CONTROL_REGISTER_OFFSET = 4;
const LINE_STATUS_REGISTER_OFFSET = 5;
const MODEM_STATUS_REGISTER_OFFSET = 6;
const SCRATCH_REGISTER_OFFSET = 7;

pub const Serial = struct {
    port: u16,

    /// Initialise default serial port (COM1)
    pub fn init() Serial {
        return initCom(COM1);
    }

    /// Initialise with specific serial port
    pub fn initCom(port: u16) Serial {
        return Serial{
            .port = port,
        };
    }

    pub fn initPreInterrupt(self: *const Serial) void {
        // Initialise simple print-only output
        // No interrupts, 115200, 8N1
        // When writing a string, block until the entire string is written.

        // Disable interrupts
        x86.outb(self.port + INTERRUPT_ENABLE_REGISTER_OFFSET, 0x0);
        // Enable DLAB (Divisor latch access bit) so we can set the divisor
        x86.outb(self.port + LINE_CONTROL_REGISTER_OFFSET, 0x80);
        // Set divisor to 115200 - set LSB to 1, MSB to 0
        x86.outb(self.port + DIVISOR_LSB_OFFSET, 0x1);
        x86.outb(self.port + DIVISOR_MSB_OFFSET, 0x0);
        // 8N1
        x86.outb(self.port + LINE_CONTROL_REGISTER_OFFSET, 0x03);
        // Enable FIFO, 14 bytes, cleared
        //x86.outb(self.port + INTERRUPT_FIFO_REGISTER_OFFSET, 0xc7);
        // Enable IRQs, set RTS/DSR
        //x86.outb(self.port + MODEM_CONTROL_REGISTER_OFFSET, 0x0b);

        // Test serial chip by setting loopback and sending 0xae and checking for return
        x86.outb(self.port + MODEM_CONTROL_REGISTER_OFFSET, 0x1e);
        const testByte = 0xae;
        x86.outb(self.port, testByte);

        // Check for test byte
        if (x86.inb(self.port) != testByte) {
            // Maybe we could write something to the screen?  A bit early to indiciate erro
            return;
        }

        // Looks ok, disable loopback, enable OUT1 and OUT2 bits
        // Would normally enable IRQs here, but we're not doing that yet (commented out)
        x86.outb(self.port + MODEM_CONTROL_REGISTER_OFFSET, 0x0f);
        //x86.outb(self.port + MODEM_CONTROL_REGISTER_OFFSET, 0x0c);
    }

    fn transmitterEmpty(self: *const Serial) bool {
        return (x86.inb(self.port + LINE_STATUS_REGISTER_OFFSET) & 0x20) > 0;
    }

    pub fn printChar(self: *const Serial, c: u8) void {
        while (!self.transmitterEmpty()) {}
        x86.outb(self.port, c);
    }

    pub fn print(self: *const Serial, str: []const u8) void {
        for (str) |c| {
            self.printChar(c);
        }
    }
};