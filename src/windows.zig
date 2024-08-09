const std = @import("std");
const Backend = @import("lib.zig").Backend;
const BackendError = @import("lib.zig").BackendError;
const Window = @import("lib.zig").Window;
const assert = std.debug.assert;

const c = @cImport({
    @cInclude("windows.h");
});

pub fn init(self: *Backend, allocator: std.mem.Allocator) BackendError!void {
    _ = self;
    _ = allocator;
    std.log.warn("init windows", .{});
}

pub fn deinit(self: *Backend) void {
    _ = self;
}

pub fn processEvents(backend: *Backend, wait: bool) void {
    _ = wait;
    _ = backend;
}

pub fn getProcAddress(self: *Backend, proc: [:0]const u8) ?*const anyopaque {
    _ = self;
    _ = proc;
    return null;
}

pub fn initWindow(self: *Backend, window: *Window) !void {
    _ = self;
    _ = window;
}

pub fn deinitWindow(window: *Window) void {
    _ = window;
}

pub fn swapWindowBuffer(self: *Backend, window: *Window) void {
    _ = self;
    _ = window;
}
