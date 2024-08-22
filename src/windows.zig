const std = @import("std");
const Platform = @import("lib.zig");
const BackendError = @import("lib.zig").BackendError;
const Window = @import("lib.zig").Window;
const WindowId = @import("lib.zig").WindowId;
const assert = std.debug.assert;
const os = std.os.windows;

const c = @cImport({
    @cDefine("WIN32_LEAN_AND_MEAN", {});
    @cInclude("windows.h");
    @cInclude("d3d11.h");
});

pub const WindowData = struct {
    handle: c.HWND = undefined,
};

const Windows = @This();

pub fn init(self: *Windows, allocator: std.mem.Allocator) BackendError!void {
    _ = self;
    _ = allocator;
    std.log.warn("init windows", .{});
}

pub fn deinit(self: *Windows) void {
    _ = self;
}

pub fn processEvents(backend: *Windows, wait: bool) void {
    _ = wait;
    _ = backend;
    var msg: c.MSG = undefined;
    while (c.PeekMessageA(&msg, null, 0, 0, c.PM_REMOVE) != 0) {
        if (msg.message == c.WM_QUIT) {
            Platform.writeEvent(.{ .exit = {} });
            return;
        }
        _ = c.TranslateMessage(&msg);
        _ = c.DispatchMessageA(&msg);
    }
}

pub fn getProcAddress(self: *Windows, proc: [:0]const u8) ?*const anyopaque {
    _ = self;
    _ = proc;
    return null;
}

pub fn initWindow(self: *Windows, window: *Window) !void {
    _ = self;
    std.log.debug("Window: {any}", .{window});

    window.backend = .{ .windows = WindowData{} };
    const instance = c.GetModuleHandleA(null);
    var wndClass = c.WNDCLASSEX{
        .cbSize = @sizeOf(c.WNDCLASSEX),
        .lpfnWndProc = windowProc,
        .hInstance = instance,
        .lpszClassName = "platform",
    };
    const class = c.RegisterClassExA(&wndClass);
    if (class == 0) {
        std.log.err("Error registering window class ({d})", .{c.GetLastError()});
        return error.RegisterClass;
    }

    window.backend.windows.handle = c.CreateWindowExA(0, c.MAKEINTATOM(class), "Test Window", c.WS_OVERLAPPEDWINDOW, c.CW_USEDEFAULT, c.CW_USEDEFAULT, c.CW_USEDEFAULT, c.CW_USEDEFAULT, null, null, instance, null);
    if (window.backend.windows.handle == null) {
        std.log.err("Error creating window ({d})", .{c.GetLastError()});
        return error.CreateWindow;
    }
    _ = c.SetPropA(window.backend.windows.handle, "_platform", window);
    _ = c.ShowWindow(window.backend.windows.handle, c.SW_HIDE);
    _ = c.ShowWindow(window.backend.windows.handle, c.SW_SHOW);
}

pub fn deinitWindow(window: *Window) void {
    _ = window;
}

pub fn swapWindowBuffer(self: *Windows, window: *Window) void {
    _ = self;
    _ = window;
}

fn windowProc(hwnd: c.HWND, uMsg: c.UINT, wParam: c.WPARAM, lParam: c.LPARAM) callconv(os.WINAPI) c.LRESULT {
    const windowRef = @as(?*Window, @alignCast(@ptrCast(c.GetPropA(hwnd, "_platform"))));
    if (windowRef) |window| {
        std.log.debug("windowProc, window = {d}, uMsg = {d}", .{ window.id, uMsg });
        switch (uMsg) {
            c.WM_CLOSE => {
                Platform.writeEvent(.{ .window_close = .{ .window = window.id } });
                return 0;
            },
            c.WM_PAINT => {
                Platform.writeEvent(.{ .window_refresh = .{ .window = window.id } });
            },
            c.WM_SIZE => {
                window.width = @intCast((lParam) & 0xffff);
                window.height = @intCast((lParam >> 16) & 0xffff);
                Platform.writeEvent(.{ .window_size = .{ .window = window.id, .width = window.width, .height = window.height } });
            },
            else => {},
        }
    } else {
        std.log.debug("windowProc, uMsg = {d}", .{uMsg});
        switch (uMsg) {
            else => {},
        }
    }
    return c.DefWindowProcA(hwnd, uMsg, wParam, lParam);
}
