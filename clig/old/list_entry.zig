const AnyNode = @import("../clig.zig").AnyNode;
const IoCtx = @import("../clig.zig").IoCtx;
const std = @import("std");

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
        std.debug.print("  list entry found\n", .{});

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
                // next word if the cmdline has enough
                // if it doesn't, try next list entry
                // if it does, do the next word
                if (input.tokens.next()) |t| {
                    a_token = t;
                } else {
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
