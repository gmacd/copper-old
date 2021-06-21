//! Raspi mailbox code, largely taken from https://github.com/andrewrk/clashos
//! Mailbox interface: https://github.com/raspberrypi/firmware/wiki/Mailbox-property-interface

const log = @import("serial.zig").log;
//const panic = @import("debug.zig").panic;
const SliceIterator = @import("slice_iterator.zig");
const time = @import("time.zig");
const aarch64 = @import("aarch64.zig");
const mmio = @import("mmio.zig");
const std = @import("std");
const assert = std.debug.assert;

pub const SET_CLOCK_RATE = 0x38002;

const mailbox0VcToArm = Mailbox.init(0);
const mailbox1ArmToVc = Mailbox.init(1);

/// Send the message via the mailbox, blocking until it receives a response.
/// The responses will be embedded in the 'out' parameters supplies in args.
pub fn sendMsg(args: []Arg) void {
    var words: [1024]u32 align(16) = undefined;
    var buf = SliceIterator.of(u32).init(&words);
    const bufsize = buildMsg(args, &buf);

    var buffer_pointer = @ptrToInt(buf.data.ptr);
    if (buffer_pointer & 0xF != 0) {
        //panic(@errorReturnTrace(), "video core mailbox buffer not aligned to 16 bytes", .{});
    }
    const PROPERTY_CHANNEL = 8;
    const request = PROPERTY_CHANNEL | @intCast(u32, buffer_pointer);
    mailbox1ArmToVc.pushRequestBlocking(request);
    //  log("pull mailbox response");
    mailbox0VcToArm.pullResponseBlocking(request);

    parseMsgResponse(args, &buf, bufsize);
    //  log("properties done");
}

/// Take a message in the form of an array of Args, and build a message of the type
/// expected by the mailbox API, using the given buffer.
/// Returns the length of the message built in bytes.
fn buildMsg(args: []Arg, buf: *SliceIterator.of(u32)) u32 {
    assert(args[args.len - 1].TagAndLength.tag == TAG_LAST_SENTINEL);

    var buffer_length_in_bytes: u32 = 0;
    buf.add(buffer_length_in_bytes);
    const BUFFER_REQUEST = 0;
    buf.add(BUFFER_REQUEST);
    var next_tag_index = buf.index;
    for (args) |arg| {
        switch (arg) {
            Arg.TagAndLength => |tag_and_length| {
                if (tag_and_length.tag != 0) {
                    //                  log("prepare tag {x} length {}", tag_and_length.tag, tag_and_length.length);
                }
                buf.index = next_tag_index;
                buf.add(tag_and_length.tag);
                if (tag_and_length.tag != TAG_LAST_SENTINEL) {
                    buf.add(tag_and_length.length);
                    const TAG_REQUEST = 0;
                    buf.add(TAG_REQUEST);
                    next_tag_index = buf.index + tag_and_length.length / 4;
                }
            },
            Arg.Out => {},
            Arg.In => |value| {
                buf.add(value);
            },
            Arg.Set => |ptr| {
                buf.add(ptr.*);
            },
        }
    }
    buffer_length_in_bytes = buf.index * 4;
    buf.reset();
    buf.add(buffer_length_in_bytes);
    return buffer_length_in_bytes;
}

fn parseMsgResponse(args: []Arg, buf: *SliceIterator.of(u32), bufsize: u32) void {
    buf.reset();
    check(buf, bufsize);
    const BUFFER_RESPONSE_OK = 0x80000000;
    check(buf, BUFFER_RESPONSE_OK);
    var next_tag_index = buf.index;
    for (args) |arg| {
        switch (arg) {
            Arg.TagAndLength => |tag_and_length| {
                if (tag_and_length.tag != 0) {
                    //                  log("parse   tag {x} length {}", tag_and_length.tag, tag_and_length.length);
                }
                buf.index = next_tag_index;
                check(buf, tag_and_length.tag);
                if (tag_and_length.tag != TAG_LAST_SENTINEL) {
                    check(buf, tag_and_length.length);
                    const TAG_RESPONSE_OK = 0x80000000;
                    check(buf, TAG_RESPONSE_OK | tag_and_length.length);
                    next_tag_index = buf.index + tag_and_length.length / 4;
                }
            },
            Arg.Out => |ptr| {
                ptr.* = buf.next();
            },
            Arg.In => {},
            Arg.Set => |ptr| {
                check(buf, ptr.*);
            },
        }
    }
}

pub fn out(ptr: *u32) Arg {
    return Arg{ .Out = ptr };
}

pub fn in(value: u32) Arg {
    return Arg{ .In = value };
}

pub const TAG_LAST_SENTINEL = 0;

pub fn set(ptr: *u32) Arg {
    return Arg{ .Set = ptr };
}

pub fn tag(the_tag: u32, length: u32) Arg {
    return Arg{ .TagAndLength = TagAndLength{ .tag = the_tag, .length = length } };
}

pub const Arg = union(enum) {
    In: u32,
    Out: *u32,
    Set: *u32,
    TagAndLength: TagAndLength,
};

const TagAndLength = struct {
    tag: u32,
    length: u32,
};

fn check(buf: *SliceIterator.of(u32), word: u32) void {
    const was = buf.next();
    if (was != word) {
        //panic(@errorReturnTrace(), "video core mailbox failed index {} was {}/{x} expected {}/{x}", .{ buf.index - 1, was, was, word, word });
    }
}

const Mailbox = packed struct {
    push_pull_register: u32,
    unused1: u32,
    unused2: u32,
    unused3: u32,
    unused4: u32,
    unused5: u32,
    status_register: u32,
    unused6: u32,

    fn init(index: u32) *Mailbox {
        if (index > 1) {
            //panic(@errorReturnTrace(), "mailbox index {} exceeds 1", .{index});
        }
        const PERIPHERAL_BASE = 0x3F000000;
        const MAILBOXES_OFFSET = 0xB880;
        assert(@sizeOf(Mailbox) == 0x20);
        return @intToPtr(*Mailbox, PERIPHERAL_BASE + MAILBOXES_OFFSET + index * @sizeOf(Mailbox));
    }

    fn pushRequestBlocking(this: *Mailbox, request: u32) void {
        blockWhile(this, isFull);
        this.push(request);
    }

    fn pullResponseBlocking(this: *Mailbox, request: u32) void {
        blockWhile(this, isEmpty);
        const response = this.pull();
        if (response != request) {
            //panic(@errorReturnTrace(), "buffer address and channel response was {x} expecting {x}", .{ response, request });
        }
    }

    fn push(this: *Mailbox, word: u32) void {
        aarch64.dsb();
        mmio.write(@ptrToInt(&this.push_pull_register), word);
    }

    fn pull(this: *Mailbox) u32 {
        return mmio.read(@ptrToInt(&this.push_pull_register));
    }

    fn status(this: *Mailbox) u32 {
        return mmio.read(@ptrToInt(&this.status_register));
    }

    fn blockWhile(this: *Mailbox, conditionFn: fn (*Mailbox) bool) void {
        time.update();
        const start = time.seconds;
        while (conditionFn(this)) {
            time.update();
            if (time.seconds - start >= 0.1) {
                //panic(@errorReturnTrace(), "time out waiting for video core mailbox", .{});
            }
        }
    }
};

fn isFull(this: *Mailbox) bool {
    const MAILBOX_IS_FULL = 0x80000000;
    return this.status() & MAILBOX_IS_FULL != 0;
}

fn isEmpty(this: *Mailbox) bool {
    const MAILBOX_IS_EMPTY = 0x40000000;
    return this.status() & MAILBOX_IS_EMPTY != 0;
}

const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

test "buildMsg" {
    const clockId: u32 = 2;
    const clockRateHz: u32 = 3000000;
    const clockSkipSettingTurbo: u32 = 0;

    var mailboxMsg = [_]Arg{
        tag(SET_CLOCK_RATE, 12),
        in(clockId),
        in(clockRateHz),
        in(clockSkipSettingTurbo),
        tag(TAG_LAST_SENTINEL, 0),
    };

    var bufArray: [1024]u32 align(16) = undefined;
    var buf = SliceIterator.of(u32).init(&bufArray);
    const bufsize = buildMsg(&mailboxMsg, &buf);

    const expectedArray = [_]u32{ bufsize, 0, SET_CLOCK_RATE, 12, 0, clockId, clockRateHz, clockSkipSettingTurbo, 0 };
    try expectEqual(expectedArray.len, bufsize / 4);
    try expectEqualSlices(u32, &expectedArray, bufArray[0..expectedArray.len]);
}
