pub const Literal = @import("./literal.zig").Literal;
pub const SimpleArg = @import("./simple_arg.zig").SimpleArg;
// pub const Root = @import("./root.zig").Root;
// pub const ListEntry = @import("./list_entry.zig").ListEntry;
pub const clig = @import("../clig.zig");

const std = @import("std");

// union holding all possible cli cmd types.
pub const AnyNode = union(enum) {
    literal: Literal,
    simpleArg: SimpleArg,
    // root: Root,
    // list_entry: ListEntry,

    pub fn run(self: AnyNode, input: *clig.IoCtx) bool {
        std.debug.print("  running any...\n", .{});
        return switch (self) {
            inline else => |node| node.run(input),
        };
    }
};
