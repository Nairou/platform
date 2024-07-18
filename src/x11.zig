const std = @import("std");
const common = @import("common.zig");

pub const platform: common.Platform = .{
    .init = init,
    .deinit = deinit,
};

fn init(allocator: std.mem.Allocator) common.PlatformError!void {
    // ...
    _ = allocator;
    std.log.warn("init x11", .{});
}

fn deinit() void {}
