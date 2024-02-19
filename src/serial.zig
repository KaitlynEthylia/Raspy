const fmt = @import("std").fmt;

const MMIO = @import("mem.zig").MMIO;
const Buf = @import("buf.zig").Buf;

const PBASE = 0x3F000000;

const GPFSEL1 = PBASE + 0x0020_0004;
const GPSET0 = PBASE + 0x0020_001C;
const GPCLR0 = PBASE + 0x0020_0028;
const GPPUD = PBASE + 0x0020_0094;
const GPPUDCLK0 = PBASE + 0x0020_0098;

const AUX_ENABLES = PBASE + 0x0021_5004;
const AUX_MU_IO_REG = PBASE + 0x0021_5040;
const AUX_MU_IER_REG = PBASE + 0x0021_5044;
const AUX_MU_IIR_REG = PBASE + 0x0021_5048;
const AUX_MU_LCR_REG = PBASE + 0x0021_504C;
const AUX_MU_MCR_REG = PBASE + 0x0021_5050;
const AUX_MU_LSR_REG = PBASE + 0x0021_5054;
const AUX_MU_MSR_REG = PBASE + 0x0021_5058;
const AUX_MU_SCRATCH = PBASE + 0x0021_505C;
const AUX_MU_CNTL_REG = PBASE + 0x0021_5060;
const AUX_MU_STAT_REG = PBASE + 0x0021_5064;
const AUX_MU_BAUD_REG = PBASE + 0x0021_5068;

extern fn delay(usize) void;

pub const Serial = struct {
    const io = MMIO(u32);

    pub fn init() void {
        var selector = io.get(GPFSEL1);
        selector &= ~@as(u32, 7 << 12);
        selector |= 1 << 13;
        selector &= ~@as(u32, 7 << 15);
        selector |= 1 << 16;
        io.put(GPFSEL1, selector);

        io.put(GPPUD, 0);
        delay(150);
        io.put(GPPUDCLK0, 3 << 14);
        delay(150);
        io.put(GPPUDCLK0, 0);

        io.put(AUX_ENABLES, 1);
        io.put(AUX_MU_CNTL_REG, 0);
        io.put(AUX_MU_IER_REG, 0);
        io.put(AUX_MU_LCR_REG, 3);
        io.put(AUX_MU_MCR_REG, 0);
        io.put(AUX_MU_BAUD_REG, 270);

        io.put(AUX_MU_CNTL_REG, 3);
    }

    pub fn send(c: c_char) void {
        while (io.get(AUX_MU_LSR_REG) & 0x20 == 0) continue;
        io.put(AUX_MU_IO_REG, c);
    }

    pub fn recv() c_char {
        while (io.get(AUX_MU_LSR_REG) & 0x01 == 0) continue;
        return @truncate(io.get(AUX_MU_IO_REG));
    }

    pub fn send_string(str: []const u8) void {
        for (str) |c| send(c);
    }

    pub fn send_num(_num: usize, base: u8) void {
        var num = _num;
        var buf: Buf(16, u8) = .{};

        while (true) : (num = num / base) {
            const digit: u8 = @truncate(num % base);
            const c = fmt.digitToChar(digit, .upper);
            buf.insert(c);
            if (num < base) break;
        }
        while (true) : (buf.i -= 1) {
            send(buf.buf[buf.i]);
            if (buf.i == 0) break;
        }
    }
};
