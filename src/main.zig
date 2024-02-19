const std = @import("std");

const Buf = @import("buf.zig").Buf;
const Serial = @import("serial.zig").Serial;

comptime {
    asm (
        \\.section .text.boot
        \\.global _start
        \\_start:
        \\  MRS X0, MPIDR_EL1
        \\  AND X0, X0, 0xFF
        \\  CBZ X0, prim
        \\hang:
        \\  B hang
        \\
        \\prim:
        \\  MOV SP, 0x80000
        \\
        \\  MOV X0, bss_start
        \\  MOV X1, bss_end
        \\  BL memzero
        \\
        \\  BL kmain
        \\  B hang
        \\
        \\.global delay
        \\delay:
        \\  SUBS X0, X0, #1
        \\  BNE delay
        \\  RET
    );
}

pub export fn kmain() void {
    Serial.init();
    Serial.send_string("Hello, World!\n");
    var buf: Buf(128, u8) = .{};
    while (true) {
        const c = Serial.recv();
        if (c == '\r') {
            Serial.send('\n');
            for (0..buf.i) |j| Serial.send(buf.buf[j]);
            Serial.send_string(" | ");
            Serial.send_num(buf.i, 10);
            Serial.send_string(" Chars.\n");
            buf.i = 0;
        } else buf.insert(c);
        Serial.send(c);
    }
}

pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    Serial.send('\n');
    Serial.send_string("!!PANIC!!\n");
    Serial.send_string(message);
    Serial.send('\n');
    while (true) continue;
}
