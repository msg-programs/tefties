// better comment this while my head still hurts...

const std = @import("std");
const AnyNode = @import("nodes.zig").AnyNode;

// the input as supplied, split by spaces, as an iterator.
pub const IoCtx = struct {
    tokens: std.mem.TokenIterator(u8, std.mem.DelimiterType.scalar),
    args: std.hash_map.StringHashMap([]const u8),

    pub fn init(input: []const u8, alloc: std.mem.Allocator) IoCtx {
        return IoCtx{
            .tokens = std.mem.tokenizeScalar(u8, input, ' '),
            .args = std.hash_map.StringHashMap([]const u8).init(alloc),
        };
    }

    pub fn getInvalidToken(self: *IoCtx) []const u8 {
        if (self.tokens.index <= self.tokens.buffer.len) {
            return "[Unexpected EOL]";
        }
        return self.tokens.buffer[self.tokens.index..];
    }
};

// abstract cli cmd type and cli parsing driver
// a cli token is a logical unit of the entered command.
// when encountered, some action is taken:
//   - try to parse one of the tokens that may follow this token
//   - try to run a function that acts on everything encountered so far and end parsing
pub const Node = struct {
    // the concrete cli cmd implementation that does the parsing/consumption
    impl: AnyNode,

    // the action to take if correct input was found.
    //   - parse the next token
    //   - run a function as supplied and end
    action: union(enum) {
        cmds: []const Node,
        func: *const fn (*IoCtx) void,
    },

    pub fn createWithCmds(impl: AnyNode, cmd: []const Node) Node {
        return Node{
            .impl = impl,
            .action = .{ .cmds = cmd },
        };
    }

    pub fn createWithFunc(impl: AnyNode, func: *const fn (*IoCtx) void) Node {
        return Node{
            .impl = impl,
            .action = .{ .func = func },
        };
    }

    // entry point for cli parsing
    // parse the current token with the impl.
    // if ok, run the associated action
    pub fn run(self: Node, input: *IoCtx) bool {
        std.debug.print("  running cmd with input {s}\n", .{input.tokens.buffer[input.tokens.index..]});
        // std.time.sleep(1 * std.time.ns_per_s);
        const ok = self.impl.run(input);

        if (ok) {
            std.debug.print("  returned true\n", .{});
            return switch (self.action) {
                .cmds => self.nextCmd(input),
                .func => self.execFunc(input),
            };
        } else {
            std.debug.print("  returned false\n", .{});
            return false;
        }
    }

    // try to find any cmd in the list that works and run it
    fn nextCmd(self: Node, input: *IoCtx) bool {
        std.debug.print("  found cmds, trying next...\n", .{});
        for (self.action.cmds) |cmd| {
            if (cmd.run(input)) {
                std.debug.print("  returned true\n", .{});
                return true;
            }
        }
        std.debug.print("  nothing found\n", .{});
        return false;
    }

    // exec the function and stop.
    fn execFunc(self: Node, input: *IoCtx) bool {
        std.debug.print("  found func, executing...\n", .{});
        self.action.func(input);
        return true;
    }
};
