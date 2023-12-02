const std = @import("std");
const mem = @import("std").mem;
const json = @import("std").json;
const io = @import("std").io;
const fs = @import("std").fs;

const Champion = struct {
    name: []const u8,
    traits: []const []const u8,
    tier: u8,
};

const Trait = struct {
    name: []const u8,
    levels: []const u32,
};

const Item = struct {
    name: []const u8,
    components: [2][]const u8,
};

const Data = struct {
    champions: []const Champion,
    traits: []const Trait,
    items: []const Item,
};

pub const GameData = struct {
    result: std.json.Parsed(Data),
    champ_names: []const []const u8,

    pub fn init(alloc: mem.Allocator) !GameData {
        var res = try loadData(alloc);
        var champ_names = try alloc.alloc([]const u8, res.value.champions.len);
        for (res.value.champions, 0..) |champ, idx| {
            champ_names[idx] = champ.name;
        }
        return GameData{
            .result = res,
            .champ_names = champ_names,
        };
    }

    fn loadData(alloc: mem.Allocator) !json.Parsed(Data) {
        const file = try std.fs.cwd().openFile("./data/data.json", .{});
        defer file.close();

        var ioread = std.io.bufferedReader(file.reader());
        var reader = std.json.reader(alloc, ioread.reader());
        defer reader.deinit();

        return std.json.parseFromTokenSource(Data, alloc, &reader, .{});
    }

    pub fn deinit(self: GameData) void {
        self.result.deinit();
    }

    pub fn dumpData(self: GameData) void {
        const data = self.result.value;
        for (data.champions) |c| {
            std.debug.print("name: {s}\n", .{c.name});
            std.debug.print("tier: {}\n", .{c.tier});
            std.debug.print("traits:\n", .{});
            for (c.traits) |t| {
                std.debug.print("\t{s}\n", .{t});
            }
            std.debug.print("\n", .{});
        }

        for (data.items) |i| {
            std.debug.print("name: {s}\n", .{i.name});
            std.debug.print("components:\n", .{});
            for (i.components) |c| {
                std.debug.print("\t{s}\n", .{c});
            }
            std.debug.print("\n", .{});
        }
        for (data.traits) |t| {
            std.debug.print("name: {s}\n", .{t.name});
            std.debug.print("levels:\n", .{});
            for (t.levels) |l| {
                std.debug.print("\t{}\n", .{l});
            }
            std.debug.print("\n", .{});
        }
    }
};
