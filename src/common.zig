const std = @import("std");

pub const PlatformError = error{
    FailedToConnect,
    UnsupportedDisplay,
};

pub const Platform = struct {
    init: *const fn (allocator: std.mem.Allocator) PlatformError!void,
};
