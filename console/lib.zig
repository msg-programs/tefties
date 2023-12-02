
const std = @import("std");

pub fn lib() void {
        std.debug.print("\x1b[31mHello \x1b[32mWorld\x1b[m\n", .{});
}
