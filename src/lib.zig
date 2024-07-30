const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;

pub const Backend = switch (builtin.os.tag) {
    .linux => @import("linux.zig"),
    .windows => @import("windows.zig"),
    else => @compileError("Unsupported backend"),
};

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

var backend: Backend = .{};
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

pub const Window = struct {
    id: WindowId = .{},
    width: u32,
    height: u32,
    internal: Backend.WindowData,
    eventFilter: EventFilter = .{},

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
    windows = std.ArrayList(Window).init(allocator);
    try backend.init(allocator);
}

pub fn deinit() void {
    try backend.deinit();
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

test {
    _ = Backend;
}

test "init" {
    _ = try init(std.testing.allocator);
}
