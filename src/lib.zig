const std = @import("std");
const builtin = @import("builtin");

const wayland = @import("wayland.zig");
const x11 = @import("x11.zig");
const windows = @import("windows.zig");

pub const PlatformError = error{
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

pub fn create(allocator: std.mem.Allocator) !type {
    switch (builtin.os.tag) {
        .linux => {
            var env = try std.process.getEnvMap(allocator);
            defer env.deinit();
            if (env.get("WAYLAND_DISPLAY")) |_| {
                return wayland;
            } else if (env.get("DISPLAY")) |_| {
                return x11;
            } else {
                const envSession = env.get("XDG_SESSION_TYPE") orelse "";
                if (std.mem.eql(u8, envSession, "wayland")) {
                    return wayland;
                } else if (std.mem.eql(u8, envSession, "x11")) {
                    return x11;
                } else {
                    return error.UnsupportedDisplay;
                }
            }
        },
        .windows => {
            return windows;
        },
        else => @panic("Unsupported platform"),
    }
}

test {
    //std.testing.refAllDecls(@This());

    _ = wayland;
    _ = x11;
    _ = windows;
}
