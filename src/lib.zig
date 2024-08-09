const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;

var backend: Backend = undefined;
var windows: struct {
    list: WindowMap = undefined,
    lastId: u32 = 0,
    mutex: std.Thread.Mutex = .{},
} = .{};
var events: struct {
    buffer: [std.math.maxInt(u12) + 1]Event = undefined,
    readOffset: u12 = 0,
    writeOffset: u12 = 0,
    mutex: std.Thread.Mutex = .{},

    const Buffer = @This();

    pub fn hasEvent(self: *Buffer) bool {
        self.mutex.lock();
        defer self.mutex.unlock();
        return self.readOffset != self.writeOffset;
    }

    pub fn push(self: *Buffer, event: Event) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        assert((self.writeOffset +% 1) != self.readOffset);
        self.buffer[self.writeOffset] = event;
        self.writeOffset +%= 1;
    }

    pub fn pop(self: *Buffer) ?Event {
        self.mutex.lock();
        defer self.mutex.unlock();
        if (self.readOffset != self.writeOffset) {
            defer self.readOffset +%= 1;
            return self.buffer[self.readOffset];
        }
        return null;
    }
} = .{};

pub const WindowId = u32;
const WindowMap = std.AutoHashMap(WindowId, Window);

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
    id: WindowId,
    width: u32,
    height: u32,
    class: []const u8,
    title: []const u8,
    backend: switch (builtin.os.tag) {
        .linux => union(enum) {
            wayland: @import("wayland.zig").WindowData,
            x11: @import("x11.zig").WindowData,
        },
        .windows => union(enum) {
            windows: @import("windows.zig").WindowData,
        },
        else => @compileError("Unsupported backend"),
    } = undefined,
    eventFilter: EventFilter = .{},

    pub fn create(width: u32, height: u32, class: []const u8, title: []const u8) !*Window {
        windows.mutex.lock();
        defer windows.mutex.unlock();

        windows.lastId +%= 1;
        const id = @as(WindowId, windows.lastId);
        assert(!windows.list.contains(id));
        try windows.list.putNoClobber(id, .{
            .id = id,
            .width = width,
            .height = height,
            .class = class,
            .title = title,
        });
        const ptr = windows.list.getPtr(id).?;
        switch (backend) {
            inline else => |*b| try b.initWindow(ptr),
        }
        return ptr;
    }

    pub fn fromId(id: WindowId) ?*Window {
        return windows.list.getPtr(id);
    }

    pub fn destroy(self: *Window) void {
        assert(windows.list.contains(self.id));
        assert(windows.list.getPtr(self.id) == self);
        switch (backend) {
            inline else => |*b| try b.deinitWindow(self),
        }
        windows.list.remove(self.id);
    }

    pub fn swapBuffers(window: *Window) void {
        switch (backend) {
            inline else => |*b| b.swapWindowBuffer(window),
        }
    }
};

pub const Event = union(enum) {
    none,
    close_window: struct {
        window: WindowId,
    },
    render: struct {
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

    windows.list = WindowMap.init(allocator);
}

pub fn deinit() void {
    switch (backend) {
        inline else => |*b| b.deinit(),
    }
    windows.list.deinit();
}

pub fn getProcAddress(proc: [:0]const u8) ?*const anyopaque {
    switch (backend) {
        inline else => |*b| return b.getProcAddress(proc),
    }
}

pub fn writeEvent(event: Event) void {
    events.push(event);
}

pub fn readNextEvent(wait: bool) ?Event {
    if (!events.hasEvent()) {
        switch (backend) {
            inline else => |*b| b.processEvents(wait),
        }
    }
    return events.pop();
}

test "init" {
    std.testing.log_level = .debug;
    _ = try init(std.testing.allocator);
    defer deinit();
}
