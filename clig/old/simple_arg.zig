const AnyNode = @import("../clig.zig").AnyNode;
const IoCtx = @import("../clig.zig").IoCtx;
const std = @import("std");

// match a literal token followed by some input token
pub const SimpleArg = struct {
    lit: []const u8,

    pub fn create(lit: []const u8) AnyNode {
        return AnyNode{ .simpleArg = SimpleArg{ .lit = lit } };
    }

    pub fn run(self: SimpleArg, input: *IoCtx) bool {
        std.debug.print("  simple arg found\n", .{});

        var input_valid: bool = true;
        const tokpos = input.tokens.index;

        defer {
            if (!input_valid) {
                input.tokens.index = tokpos;
            }
        }

        const token = input.tokens.next() orelse {
            std.debug.print("no more tokens for lit part!\n", .{});
            input_valid = false;
            return input_valid;
        };

        std.debug.print("  matching lit part {s} against {s}\n", .{ token, self.lit });
        if (!std.mem.eql(u8, token, self.lit)) {
            input_valid = false;
            return input_valid;
        }

        const arg = input.tokens.next() orelse {
            std.debug.print("no more tokens for arg!\n", .{});
            input_valid = false;
            return input_valid;
        };
        std.debug.print("  found arg, value {s}\n", .{arg});
        input.args.put(self.lit, arg) catch |err| {
            std.debug.print("alloc err {any}", .{err});
            input_valid = false;
            return input_valid;
        };

        return true;
    }
};
