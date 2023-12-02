const AnyNode = @import("../clig.zig").AnyNode;
const clig = @import("../clig.zig");
const std = @import("std");

pub const Root = struct {
    pub fn create() AnyNode {
        return AnyNode{
            .root = Root{},
        };
    }

    pub fn run(self: Root, input: *clig.IoCtx) bool {
        _ = self;
        _ = input;
        return true;
    }
};
