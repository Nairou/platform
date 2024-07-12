const std = @import("std");
const common = @import("common.zig");

pub const c = @cImport({
    //@cDefine("GLFW_INCLUDE_NONE", "1");
    @cInclude("wayland-client-core.h");
});

pub const platform: common.Platform = .{
    .init = init,
};

fn init(allocator: std.mem.Allocator) common.PlatformError!void {
    // ...
    _ = allocator;
    std.log.warn("init wayland", .{});

    const display = c.wl_display_connect(null) orelse return error.FailedToConnect;
    std.log.warn("Connection established!", .{});

    c.wl_display_disconnect(display);
}
