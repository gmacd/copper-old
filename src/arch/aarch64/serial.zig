//! Uart provides functions to allow writing to the serial port at
//! as early a stage as possible.

const mmio = @import("mmio.zig");
const aarch64 = @import("aarch64.zig");
const mailbox = @import("mailbox.zig");
const sys = @import("../../sys.zig");

// TODO A lot of these consts maybe shouldn't be here

// General Purpose IO (base is offset from MMIO_BASE)
const GPIO_BASE = 0x200000;

// Controls actuation of pull up/down to ALL GPIO pins
const GPPUD = GPIO_BASE + 0x94;

// Controls actuation of pull up/down for specific GPIO pin
const GPPUDCLK0 = GPIO_BASE + 0x98;

// UARTs
const UART0_BASE = GPIO_BASE + 0x1000;

// The offsets for reach register for the UART
const UART_DR = 0x00;
const UART_RSRECR = 0x04;
const UART_FR = 0x18;
const UART_ILPR = 0x20;
const UART_IBRD = 0x24;
const UART_FBRD = 0x28;
const UART_LCRH = 0x2c;
const UART_CR = 0x30;
const UART_IFLS = 0x34;
const UART_IMSC = 0x38;
const UART_RIS = 0x3c;
const UART_MIS = 0x40;
const UART_ICR = 0x44;
const UART_DMACR = 0x48;
const UART_ITCR = 0x80;
const UART_ITIP = 0x84;
const UART_ITOP = 0x88;
const UART_TDR = 0x8c;

// TODO we probably need a mailbox file
// The offsets for Mailbox registers
const MBOX_BASE = 0xb880;
const MBOX_READ = MBOX_BASE + 0x00;
const MBOX_STATUS = MBOX_BASE + 0x18;
const MBOX_WRITE = MBOX_BASE + 0x20;

// A Mailbox message with set clock rate of PL011 to 3MHz tag
//var mboxClock align(@alignOf(u32)) = *volatile u32{
// var mboxClock align(@alignOf(u32)) = [_]volatile u32{
//     9 * 4,
//     0,
//     0x38002,
//     12,
//     8,
//     2,
//     3000000,
//     0,
//     0,
// };

//volatile unsigned int  __attribute__((aligned(16))) mbox[9] = {
//    9*4, 0, 0x38002, 12, 8, 2, 3000000, 0 ,0
//};

pub const Serial = struct {
    serial: sys.Serial,
    uartBase: u32,

    pub fn init() Serial {
        var uartBase: u32 = UART0_BASE;

        // Disable uart
        mmio.write(uartBase + UART_CR, 0x0);

        // Setup GPIO pins 14 and 15
        // Disable pull up/down for all GPIO pins & delay for 150 cycles
        mmio.write(GPPUD, 0x0);
        // TODO replace with time.xxx code?
        aarch64.delay(150);

        // Disable pull up/down for pin 14 and 15 & delay for 150 cycles
        mmio.write(GPPUDCLK0, (1 << 14) | (1 << 15));
        // TODO replace with time.xxx code?
        aarch64.delay(150);

        // Write 0 to GPPUDCLK0 to make it take effect
        mmio.write(GPPUDCLK0, 0x0);

        // Clear pending interrupts.
        mmio.write(uartBase + UART_ICR, 0x7ff);

        // Set integer & fractional part of baud rate.
        // Divider = UART_CLOCK/(16 * Baud)
        // Fraction part register = (Fractional part * 64) + 0.5
        // Baud = 115200.

        //var r: [*]u32 = &mboxClock;

        // For Raspi3 and 4 the UART_CLOCK is system-clock dependent by default.
        // Set it to 3Mhz so that we can consistently set the baud rate
        const clockId: u32 = 2;
        const clockRateHz: u32 = 3000000;
        const clockSkipSettingTurbo: u32 = 0;
        var mailboxMsg = [_]mailbox.Arg{
            mailbox.tag(mailbox.SET_CLOCK_RATE, 12),
            mailbox.in(clockId),
            mailbox.in(clockRateHz),
            mailbox.in(clockSkipSettingTurbo),
            mailbox.tag(mailbox.TAG_LAST_SENTINEL, 0),
        };
        mailbox.sendMsg(&mailboxMsg);

        //var r: u32 = @ptrToInt(((&mboxClock) & ~0xF) | 8);
        // wait until we can talk to the VChttps://github.com/ziglang/zig/issues/265 is
        //while (mmio.read(MBOX_STATUS) & 0x80000000) {}
        // send our message to property channel and wait for the response
        //mmio.write(MBOX_WRITE, r);
        //while ((mmio.read(MBOX_STATUS) & 0x40000000) || mmio.read(MBOX_READ) != r) {}

        // Divider = 3000000 / (16 * 115200) = 1.627 = ~1.
        mmio.write(uartBase + UART_IBRD, 1);
        // Fractional part register = (.627 * 64) + 0.5 = 40.6 = ~40.
        mmio.write(uartBase + UART_FBRD, 40);

        // Enable FIFO & 8 bit data transmission (1 stop bit, no parity).
        mmio.write(uartBase + UART_LCRH, (1 << 4) | (1 << 5) | (1 << 6));

        // Mask all interrupts.
        mmio.write(uartBase + UART_IMSC, (1 << 1) | (1 << 4) | (1 << 5) | (1 << 6) |
            (1 << 7) | (1 << 8) | (1 << 9) | (1 << 10));

        // Enable UART0, receive & transfer part of UART.
        mmio.write(uartBase + UART_CR, (1 << 0) | (1 << 8) | (1 << 9));

        return Serial{
            .uartBase = uartBase,
            .serial = sys.Serial{
                .printFn = print,
            },
        };
    }

    fn transmitterEmpty(uartBase: u32) bool {
        return mmio.read(uartBase + UART_FR) & (1 << 5) > 0;
    }

    pub fn printChar(uartBase: u32, c: u8) void {
        while (!transmitterEmpty(uartBase)) {}
        mmio.write(uartBase + UART_DR, c);
    }

    pub fn print(serial: *sys.Serial, str: []const u8) void {
        const self = @fieldParentPtr(Serial, "serial", serial);
        for (str) |c| {
            printChar(self.uartBase, c);
        }
    }
};
