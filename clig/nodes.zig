const IoCtx = @import("clig.zig").IoCtx;

const std = @import("std");

// a literal token
// match a single word to the current token
pub const Literal = struct {
    lit: []const u8,

    pub fn create(lit: []const u8) AnyNode {
        return AnyNode{ .literal = Literal{ .lit = lit } };
    }

    pub fn run(self: Literal, input: *IoCtx) bool {
        std.debug.print("  literal {s} found\n", .{self.lit});

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

// match a literal token followed by some input token
pub const SimpleArg = struct {
    lit: []const u8,

    pub fn create(lit: []const u8) AnyNode {
        return AnyNode{ .simpleArg = SimpleArg{ .lit = lit } };
    }

    pub fn run(self: SimpleArg, input: *IoCtx) bool {
        std.debug.print("  simple arg {s} found\n", .{self.lit});

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

// a list token
// match a single literal and then try to find an entry in the list.
// if the entry contains spaces, consume tokens accordingly
pub const ListEntry = struct {
    lit: []const u8,
    list: []const []const u8,

    pub fn create(lit: []const u8, list: []const []const u8) AnyNode {
        return AnyNode{ .list_entry = ListEntry{ .lit = lit, .list = list } };
    }

    pub fn run(self: ListEntry, input: *IoCtx) bool {
        std.debug.print("  list entry {s} found\n", .{self.lit});

        var input_valid: bool = true;
        const tokpos = input.tokens.index;

        defer {
            if (!input_valid) {
                input.tokens.index = tokpos;
            }
        }

        const token = input.tokens.next() orelse {
            std.debug.print("no more tokens!\n", .{});
            input_valid = false;
            return input_valid;
        };

        std.debug.print("  matching lit part {s} against {s}\n", .{ token, self.lit });
        if (!std.mem.eql(u8, token, self.lit)) {
            input_valid = false;
            return input_valid;
        }

        var a_token = input.tokens.next() orelse {
            std.debug.print("no more tokens!\n", .{});
            input_valid = false;
            return input_valid;
        };

        // index where the possible list entry could start
        const fallback = input.tokens.index;
        // iterate over the list entries...
        next: for (self.list) |entry| {
            std.debug.print("  matching list part, current entry is {s}\n", .{entry});
            // ...split the entry by space...
            var entry_parts = std.mem.tokenizeScalar(u8, entry, ' ');
            // ... and compare word for word.
            while (entry_parts.next()) |part| {
                // word doesn't match? next entry.
                std.debug.print("  matching word {s} against {s}\n", .{ part, a_token });
                if (!std.mem.eql(u8, part, a_token)) {
                    input.tokens.index = fallback;
                    continue :next;
                }
                std.debug.print("  equal, looking for next word...", .{});

                _ = entry_parts.peek() orelse {
                    std.debug.print("  no next word needed, end!", .{});
                    // continue to end loop to prevent nesting deeply
                    continue;
                };

                // next word if the cmdline has enough
                // if it doesn't, try next list entry
                // if it does, do the next word
                if (input.tokens.next()) |t| {
                    std.debug.print("  found, next...", .{});
                    a_token = t;
                } else {
                    std.debug.print("  not found, falling back...", .{});
                    input.tokens.index = fallback;
                    continue :next;
                }
            }
            // we got here without continueing :next.
            // list entry found, save and return
            std.debug.print("  ok, saving {s}\n", .{self.lit});
            input.args.put(self.lit, entry) catch |err| {
                std.debug.print("alloc err {any}", .{err});
                input_valid = false;
                return input_valid;
            };
            input_valid = true;
            return input_valid;
        }
        // we got here, so nothing was found.
        // reset and return

        input_valid = false;
        return input_valid;
    }
};

// an empty token that only delegates to its children
// useful for the cmd root, hence the name
pub const Root = struct {
    pub fn create() AnyNode {
        return AnyNode{
            .root = Root{},
        };
    }

    pub fn run(self: Root, input: *IoCtx) bool {
        std.debug.print("  root found\n", .{});
        _ = self;
        _ = input;
        return true;
    }
};

// union holding all possible cli cmd types.
pub const AnyNode = union(enum) {
    literal: Literal,
    simpleArg: SimpleArg,
    root: Root,
    list_entry: ListEntry,

    pub fn run(self: AnyNode, input: *IoCtx) bool {
        std.debug.print("  running any...\n", .{});
        return switch (self) {
            inline else => |node| node.run(input),
        };
    }
};
