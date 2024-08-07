const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;

var backend: Backend = undefined;
var windows: std.ArrayList(Window) = undefined;
var events: struct {
    buffer: [std.math.maxInt(u12) + 1]Event = undefined,
    readOffset: u12 = 0,
    writeOffset: u12 = 0,

    const Buffer = @This();

    pub fn push(self: *Buffer, event: Event) void {
        assert((self.writeOffset +% 1) != self.readOffset);
        self.buffer[self.writeOffset] = event;
        self.writeOffset +%= 1;
    }

    pub fn pop(self: *Buffer) ?Event {
        if (self.readOffset != self.writeOffset) {
            defer self.readOffset +%= 1;
            return self.buffer[self.readOffset];
        }
        return null;
    }
} = .{};

pub const BackendError = error{
    CantCreateBuffer,
    CantCreatePool,
    CantLoadGlExtensions,
    EglUnavailable,
    FailedToConnect,
    ShmFileError,
    ShmFileExists,
    ShmMapError,
    UnsupportedDisplay,
};

pub const Backend = switch (builtin.os.tag) {
    .linux => union(enum) {
        wayland: @import("wayland.zig"),
        x11: @import("x11.zig"),
    },
    .windows => union(enum) {
        windows: @import("windows.zig"),
    },
    else => @compileError("Unsupported backend"),
};

pub const Window = struct {
    id: WindowId = .{},
    width: u32,
    height: u32,
    backend: switch (builtin.os.tag) {
        .linux => union(enum) {
            wayland: @import("wayland.zig").WindowData,
            x11: @import("x11.zig").WindowData,
        },
        .windows => union(enum) {
            windows: @import("windows.zig").WindowData,
        },
        else => @compileError("Unsupported backend"),
    },
    eventFilter: EventFilter = .{},

    pub fn init(window: *Window, width: u32, height: u32) !void {
        window.width = width;
        window.height = height;
        switch (backend) {
            inline else => |*b| try b.initWindow(window),
        }
    }

    pub fn close(self: Window) void {
        events.push(.{
            .close_window = .{
                .window = self.id,
            },
        });
    }
};

pub const WindowId = struct {
    index: usize = 0,
    generation: u32 = 0,

    pub fn isValid(self: WindowId) bool {
        const other = windows[self.index].id;
        return self.index == other.index and self.generation == other.generation;
    }

    pub fn toPointer(self: WindowId) ?*Window {
        return if (self.isValid()) &windows[self.index] else null;
    }
};

pub const Event = union(enum) {
    none,
    close_window: struct {
        window: WindowId,
    },
};

pub const EventFilter = packed struct(u16) {
    window: bool = true,
    keyboard: bool = true,
    mouse: bool = true,

    _packed: u13 = undefined,
};

pub fn init(allocator: std.mem.Allocator) !void {
    switch (builtin.os.tag) {
        .linux => {
            var env = try std.process.getEnvMap(allocator);
            defer env.deinit();
            if (env.get("WAYLAND_DISPLAY")) |_| {
                try backend.wayland.init(allocator);
            } else if (env.get("DISPLAY")) |_| {
                try backend.x11.init(allocator);
            } else {
                const envSession = env.get("XDG_SESSION_TYPE") orelse "";
                if (std.mem.eql(u8, envSession, "wayland")) {
                    try backend.wayland.init(allocator);
                } else if (std.mem.eql(u8, envSession, "x11")) {
                    try backend.x11.init(allocator);
                } else {
                    return error.UnsupportedDisplay;
                }
            }
        },
        .windows => try backend.windows.init(allocator),
        else => @compileError("Unsupported backend"),
    }

    windows = std.ArrayList(Window).init(allocator);
}

pub fn deinit() void {
    switch (backend) {
        inline else => |*b| b.deinit(),
    }
}

pub fn processEvents() void {
    switch (backend) {
        inline else => |*b| b.processEvents(),
    }
}

pub fn getProcAddress(proc: [:0]const u8) ?*const anyopaque {
    switch (backend) {
        inline else => |*b| return b.getProcAddress(proc),
    }
}

pub fn swapWindowBuffer(window: *Window) void {
    switch (backend) {
        inline else => |*b| b.swapWindowBuffer(window),
    }
}

pub fn readNextEvent() ?Event {
    // TODO: ...
}
pub fn peekNextEvent() ?Event {
    // TODO: ...
}
pub fn waitForEvent() Event {
    // TODO: ...
}

test "init" {
    std.testing.log_level = .debug;
    _ = try init(std.testing.allocator);
    defer deinit();
}
