pub fn Buf(comptime size: u8, comptime T: type) type {
    return struct {
        const Self = @This();
        i: u8 = 0,
        buf: [size]T = undefined,

        pub fn insert(self: *Self, elem: T) void {
            self.buf[self.i] = elem;
            self.i += 1;
        }
    };
}
