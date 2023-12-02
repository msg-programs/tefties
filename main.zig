const std = @import("std");
const heap = @import("std").heap;
const io = @import("std").io;
const mem = @import("std").mem;
const builtin = @import("builtin");
const clig = @import("clig/zig");
const Node = @import("clig/clig.zig").Node;
const IoCtx = @import("clig/clig.zig").IoCtx;
const Literal = @import("clig/nodes.zig").Literal;
const SimpleArg = @import("clig/nodes.zig").SimpleArg;
const Root = @import("clig/nodes.zig").Root;
const ListEntry = @import("clig/nodes.zig").ListEntry;
// const data = @import("data.zig");

// ()>>> team
// (Team)>>> create <name>
// (Team)>>> load <name>
// (Team)>>> add <champ>
// (Team)>>> remove <champ>
// (Team)>>> core set <champ>
// (Team)>>> core unset <champ>
// (Team)>>> suggest
// (Team)>>> note <anytext>
// (Team)>>> end
// ()>>> items
// (Items)>>> select <champ>
// (Items)>>> add <item>
// (Items)>>> del <item>
// (Items)>>> save
// (Items)>>> end
// ()>>> start
// (Start)>>> got <champion>
// (Start)>>> got <component>
// (Start)>>> got <item>
// (Start)>>> list teams
// (Start)>>> suggest
// (Start)>>> reset
// (Start)>>> play <team>
// (Game)>>> show all
// (Game)>>> show <champ>
// (Game)>>> show <component>
// (Game)>>> show <item>
// (Game)>>> end
// (Game)>>> list teams
// (Game)>>> changeteam <name>
// ()>>> exit
// OK

fn dummy(ctx: *IoCtx) void {
    std.debug.print("OUT: cmd {s}, args are\n", .{ctx.tokens.buffer});
    var iter = ctx.args.keyIterator();
    while (iter.next()) |key| {
        std.debug.print(" * {s} -> {s}\n", .{ key.*, ctx.args.get(key.*).? });
    }
}

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    // var gamedat: data.GameData = try data.GameData.init(alloc);
    // defer gamedat.deinit();

    const stdout = io.getStdOut().writer();

    const stdin = io.getStdIn().reader();
    var inmem: [1024]u8 = undefined;
    var instream = io.fixedBufferStream(&inmem);

    const cmd = Node.createWithCmds(
        Root.create(),
        &[_]Node{
            Node.createWithFunc(
                SimpleArg.create("create"),
                dummy,
            ),
            Node.createWithFunc(
                SimpleArg.create("load"),
                dummy,
            ),
            Node.createWithFunc(
                ListEntry.create("add", &[_][]const u8{ "1", "2", "3 4" }), //dat.champ_names),
                dummy,
            ),
            Node.createWithFunc(
                ListEntry.create("remove", &[_][]const u8{ "1", "2" }), // dat.champ_names),
                dummy,
            ),
            Node.createWithCmds(
                Literal.create("core"),
                &[_]Node{
                    Node.createWithFunc(
                        ListEntry.create("set", &[_][]const u8{ "1", "2" }), //dat.champ_names),
                        dummy,
                    ),
                    Node.createWithFunc(
                        ListEntry.create("unset", &[_][]const u8{ "1", "2" }), // dat.champ_names),
                        dummy,
                    ),
                },
            ),
            Node.createWithFunc(
                Literal.create("suggest"),
                dummy,
            ),
            Node.createWithCmds(
                Literal.create("notes"),
                &[_]Node{
                    Node.createWithFunc(
                        SimpleArg.create("del"),
                        dummy,
                    ),
                    Node.createWithFunc(
                        Literal.create("show"),
                        dummy,
                    ),
                },
            ),
            Node.createWithFunc(
                Literal.create("end"),
                dummy,
            ),
        },
    ); //gamedat);

    try stdout.print("()>>> ", .{});

    while (stdin.streamUntilDelimiter(instream.writer(), '\n', inmem.len)) {
        defer instream.reset();

        const input: []const u8 = if (builtin.os.tag == .windows)
            mem.trimRight(u8, instream.getWritten(), "\r")
        else
            instream.getWritten();

        try stdout.print("{s}\n", .{input});

        if (mem.eql(u8, input, "exit")) {
            break;
        }

        var ctx = IoCtx.init(input, alloc);
        while (ctx.tokens.next()) |token| {
            std.debug.print("{s}\n", .{token});
        }
        ctx.tokens.reset();

        if (!cmd.run(&ctx)) {
            try stdout.print("Invalid command, choked on this: {s}\n", .{ctx.getInvalidToken()});
        }
        ctx.args.deinit();

        try stdout.print(">>> ", .{});
    } else |err| {
        std.debug.print("{any}", .{err});
        return;
    }
}
