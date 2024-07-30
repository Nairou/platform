const std = @import("std");
const platform = @import("platform");

pub fn main() anyerror!void {
    const p = try platform.init(std.heap.page_allocator);
    defer p.deinit();

    //while (!global.shouldClose) {
    //    _ = c.wl_display_dispatch(self.wl.display);
    //    //draw() catch {};
    //}
}
