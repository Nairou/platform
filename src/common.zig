const std = @import("std");

pub const PlatformError = error{
    CantCreateBuffer,
    CantCreatePool,
    FailedToConnect,
    ShmFileError,
    ShmFileExists,
    UnsupportedDisplay,
};

pub const Platform = struct {
    init: *const fn (allocator: std.mem.Allocator) PlatformError!void,
};
