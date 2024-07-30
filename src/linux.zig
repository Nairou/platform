const std = @import("std");
const wayland = @import("wayland.zig");
const x11 = @import("x11.zig");

const Window = @import("lib.zig").Window;

backend: union(enum) {
    wayland: wayland,
    x11: x11,
} = undefined,

pub const WindowData = struct {
    wlSurface: *opaque {} = undefined,
    xdgSurface: *opaque {} = undefined,
    xdgTopLevel: *opaque {} = undefined,
    eglWindow: *opaque {} = undefined,
    eglSurface: *opaque {} = undefined,
};

const Self = @This();

pub fn init(self: *Self, allocator: std.mem.Allocator) !void {
    var env = try std.process.getEnvMap(allocator);
    defer env.deinit();
    if (env.get("WAYLAND_DISPLAY")) |_| {
        self.backend.wayland = .{};
    } else if (env.get("DISPLAY")) |_| {
        self.backend.x11 = .{};
    } else {
        const envSession = env.get("XDG_SESSION_TYPE") orelse "";
        if (std.mem.eql(u8, envSession, "wayland")) {
            self.backend.wayland = .{};
        } else if (std.mem.eql(u8, envSession, "x11")) {
            self.backend.x11 = .{};
        } else {
            return error.UnsupportedDisplay;
        }
    }

    switch (self.backend) {
        inline else => |*backend| try backend.init(allocator),
    }
}

pub fn deinit(self: *Self) void {
    switch (self.backend) {
        inline else => |*backend| try backend.deinit(),
    }
}

pub fn swapWindowBuffer(self: *Self, window: *Window) void {
    switch (self.backend) {
        inline else => |*backend| try backend.swapWindowBuffer(window),
    }
}
