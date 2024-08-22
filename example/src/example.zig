const std = @import("std");
const builtin = @import("builtin");
const platform = @import("platform");
const gl = @import("zgl");

var gradient: u8 = 0;

pub fn main() anyerror!void {
    _ = try platform.init(std.heap.page_allocator);
    defer platform.deinit();

    if (builtin.os.tag == .linux) {
        gl.loadExtensions(void, glGetProcAddress) catch return error.CantLoadGlExtensions;
    }

    const window = try platform.Window.create(200, 100, "platform", "Example!");
    std.log.debug("Opened window, id = {}", .{window.id});
    draw(window.id);

    var running = true;
    while (running) {
        while (platform.readNextEvent(true)) |event| {
            switch (event) {
                .window_refresh => |window_refresh| {
                    gradient +%= 1;
                    draw(window_refresh.window);
                },
                .window_close => |_| {
                    running = false;
                    std.log.debug("Window wants to close", .{});
                },
                .window_size => |window_size| {
                    std.log.debug("Window resized to {d}x{d}", .{ window_size.width, window_size.height });
                },
                else => std.log.debug("Unknown event: {}", .{event}),
            }
        }
    }
}

fn draw(windowId: platform.WindowId) void {
    if (platform.Window.fromId(windowId)) |window| {
        if (builtin.os.tag == .linux) {
            const r = @as(f32, @floatFromInt(gradient)) / 255;
            const g = 1.0 - @as(f32, @floatFromInt(gradient)) / 255;
            gl.clearColor(r, g, 0.0, 1.0);
            gl.clear(.{ .color = true, .depth = true, .stencil = false });
        }

        window.swapBuffers();
    }
}

pub fn glGetProcAddress(comptime _: type, proc: [:0]const u8) ?*const anyopaque {
    return platform.getProcAddress(proc);
}
