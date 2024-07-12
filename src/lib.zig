const std = @import("std");
const builtin = @import("builtin");

const common = @import("common.zig");
const wayland = @import("wayland.zig");
const x11 = @import("x11.zig");
const windows = @import("windows.zig");

platform: common.Platform = undefined,

const Self = @This();

pub fn init(self: *Self, allocator: std.mem.Allocator) !void {
    // return struct, or init self?
    // select proper platform to init
    switch (builtin.os.tag) {
        .linux => {
            var env = try std.process.getEnvMap(allocator);
            defer env.deinit();
            if (env.get("WAYLAND_DISPLAY")) |_| {
                self.platform = wayland.platform;
            } else if (env.get("DISPLAY")) |_| {
                self.platform = x11.platform;
            } else {
                const envSession = env.get("XDG_SESSION_TYPE") orelse "";
                if (std.mem.eql(u8, envSession, "wayland")) {
                    self.platform = wayland.platform;
                } else if (std.mem.eql(u8, envSession, "x11")) {
                    self.platform = x11.platform;
                } else {
                    return error.UnsupportedDisplay;
                }
            }
        },
        .windows => {
            self.platform = windows.platform;
        },
        else => @panic("Unsupported platform"),
    }
    try self.platform.init(allocator);
}

test {
    std.testing.refAllDecls(@This());

    var lib = Self{};
    try lib.init(std.testing.allocator);
}
