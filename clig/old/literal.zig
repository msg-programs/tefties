const AnyNode = @import("../clig.zig").AnyNode;
const IoCtx = @import("../clig.zig").IoCtx;
const std = @import("std");

// a literal token
// match a single word to the current token
pub const Literal = struct {
    lit: []const u8,

    pub fn create(lit: []const u8) AnyNode {
        return AnyNode{ .literal = Literal{ .lit = lit } };
    }

    pub fn run(self: Literal, input: *IoCtx) bool {
        std.debug.print("  literal found\n", .{});

        const token = input.tokens.peek() orelse {
            std.debug.print("no more tokens!\n", .{});
            return false;
        };

        std.debug.print("  matching lit {s} against {s}\n", .{ token, self.lit });
        if (!std.mem.eql(u8, token, self.lit)) {
            return false;
        }
        _ = input.tokens.next();
        return true;
    }
};
