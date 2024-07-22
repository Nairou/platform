const std = @import("std");
const lib = @import("lib.zig");

fn init(allocator: std.mem.Allocator) lib.PlatformError!void {
    // ...
    _ = allocator;
    std.log.warn("init x11", .{});
}

fn deinit() void {}
