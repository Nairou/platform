const std = @import("std");
const platform = @import("platform");
const gl = @import("zgl");

pub fn main() anyerror!void {
    _ = try platform.init(std.heap.page_allocator);
    defer platform.deinit();

    gl.loadExtensions(void, glGetProcAddress) catch return error.CantLoadGlExtensions;

    var window: platform.Window = undefined;
    try window.init(200, 100);

    while (true) {
        gl.clearColor(1.0, 0.0, 0.0, 1.0);
        gl.clear(.{ .color = true, .depth = true, .stencil = false });

        platform.processEvents();
        platform.swapWindowBuffer(&window);
    }
}

pub fn glGetProcAddress(comptime _: type, proc: [:0]const u8) ?*const anyopaque {
    return platform.getProcAddress(proc);
}
