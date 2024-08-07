const std = @import("std");
const BackendError = @import("lib.zig").BackendError;
const Window = @import("lib.zig").Window;
const assert = std.debug.assert;

pub const WindowData = struct {
    // ...
};

const X11 = @This();

pub fn init(backend: *X11, allocator: std.mem.Allocator) BackendError!void {
    _ = backend;
    _ = allocator;
    std.log.warn("init x11", .{});
}

pub fn deinit(backend: *X11) void {
    _ = backend;
}

pub fn processEvents(backend: *X11) void {
    _ = backend;
}

pub fn getProcAddress(backend: *X11, proc: [:0]const u8) ?*const anyopaque {
    _ = backend;
    _ = proc;
    return null;
}

pub fn initWindow(backend: *X11, window: *Window) !void {
    _ = backend;
    _ = window;
}

pub fn deinitWindow(window: *Window) void {
    _ = window;
}

pub fn swapWindowBuffer(backend: *X11, window: *Window) void {
    _ = backend;
    _ = window;
}
