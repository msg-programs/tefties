const w32 = @cImport(@cInclude("windows.h"));
const std = @import("std");
const lib = @import("lib.zig");

pub fn main() !void {
    const console: w32.HANDLE = w32.GetStdHandle(w32.STD_OUTPUT_HANDLE);

    var dwMode: w32.DWORD = 0;
    _ = w32.GetConsoleMode(console, &dwMode);
    dwMode |= w32.ENABLE_VIRTUAL_TERMINAL_PROCESSING;
    _ = w32.SetConsoleMode(console, dwMode);
    std.debug.print("\x1b[31mHello \x1b[32mWorld\x1b[m\n", .{});
    std.time.sleep(std.time.ns_per_s * 10);
    lib.lib();
}
