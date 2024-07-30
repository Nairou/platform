const std = @import("std");
const lib = @import("lib.zig");

const Self = @This();

pub fn init(self: *Self, allocator: std.mem.Allocator) !void {
    _ = self;
    _ = allocator;
    std.log.warn("init x11", .{});
}

pub fn deinit() void {}
