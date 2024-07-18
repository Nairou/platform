const std = @import("std");

pub const PlatformError = error{
    CantCreateBuffer,
    CantCreatePool,
    FailedToConnect,
    ShmFileError,
    ShmFileExists,
    ShmMapError,
    UnsupportedDisplay,
};

pub const Platform = struct {
    init: *const fn (allocator: std.mem.Allocator) PlatformError!void,
    deinit: *const fn () void,
};
