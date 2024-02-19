const Serial = @import("serial.zig").Serial;

pub export fn memzero(start: usize, end: usize) void {
    var i = start;
    while (i < end) : (i += @sizeOf(usize))
        @as(*usize, @ptrFromInt(i)).* = 0;
}

pub fn MMIO(comptime size: type) type {
    return struct {
        pub fn get(a: usize) size {
            const addr: *volatile size = @ptrFromInt(a);
            return addr.*;
        }

        pub fn put(a: usize, c: size) void {
            const addr: *volatile size = @ptrFromInt(a);
            addr.* = c;
        }
    };
}
