const std = @import("std");
const common = @import("common.zig");

pub const platform: common.Platform = .{
    .init = init,
};

const global = struct {
    // Globals
    pub var display: *c.wl_display = undefined;
    pub var registry: *c.wl_registry = undefined;
    pub var compositor: *c.wl_compositor = undefined;
    pub var shm: *c.wl_shm = undefined;
    pub var xdgBase: *c.xdg_wm_base = undefined;

    // Objects (wait for window?)
    pub var width: i32 = 200;
    pub var height: i32 = 100;
    pub var surface: ?*c.wl_surface = undefined;
    pub var xdgSurface: *c.xdg_surface = undefined;
    pub var xdgTopLevel: *c.xdg_toplevel = undefined;
    pub var poolFile: c_int = undefined;
    pub var pool: ?*c.wl_shm_pool = undefined;
    pub var buffer: ?*c.wl_buffer = undefined;
    pub var data: []align(std.mem.page_size) u8 = undefined;

    pub var tempOffset: u32 = 0;
    pub var tempNextFrameTime: u32 = 0;
};

pub const c = @cImport({
    //@cDefine("GLFW_INCLUDE_NONE", "1");
    @cInclude("wayland-client-core.h");
    @cInclude("wayland-client-protocol.h");
    @cInclude("xdg-shell-client-protocol.h");
});

fn init(allocator: std.mem.Allocator) common.PlatformError!void {
    _ = allocator;

    std.log.warn("init wayland", .{});

    global.display = c.wl_display_connect(null) orelse return error.FailedToConnect;
    std.log.warn("Connection established!", .{});
    global.registry = c.wl_display_get_registry(global.display) orelse return error.FailedToConnect;
    _ = c.wl_registry_add_listener(global.registry, &registryListener, null);
    _ = c.wl_display_roundtrip(global.display);

    global.surface = c.wl_compositor_create_surface(global.compositor) orelse return error.FailedToConnect;
    global.xdgSurface = c.xdg_wm_base_get_xdg_surface(global.xdgBase, global.surface) orelse return error.FailedToConnect;
    _ = c.xdg_surface_add_listener(global.xdgSurface, &xdgSurfaceListener, null);
    global.xdgTopLevel = c.xdg_surface_get_toplevel(global.xdgSurface) orelse return error.FailedToConnect;
    c.xdg_toplevel_set_app_id(global.xdgTopLevel, "platform");
    c.xdg_toplevel_set_title(global.xdgTopLevel, "Sample Title");
    c.wl_surface_commit(global.surface);

    const frameCallback = c.wl_surface_frame(global.surface);
    _ = c.wl_callback_add_listener(frameCallback, &frameListener, null);

    while (c.wl_display_dispatch(global.display) != 0) {}

    c.wl_surface_destroy(global.surface);
    c.wl_display_disconnect(global.display);
}

fn createBuffer() common.PlatformError!void {
    std.log.warn("createBuffer", .{});
    const stride = global.width * 4;
    const poolSize = global.height * stride * 2;

    var shmName: [100]u8 = undefined;
    const prefix = "/platform-shm-";
    std.mem.copyForwards(u8, &shmName, prefix);
    const rngLen = 8;
    for (0..100) |_| {
        var currentTime = std.time.nanoTimestamp();
        for (0..rngLen) |i| {
            shmName[prefix.len + i] = 'A' + @as(u8, @intCast(currentTime & 15)) + @as(u8, @intCast(currentTime & 16)) * 2;
            currentTime >>= 5;
        }
        shmName[prefix.len + rngLen] = 0;
        std.log.warn("shm: '{s}'", .{shmName});
        global.poolFile = std.c.shm_open(@ptrCast(&shmName), @bitCast(std.os.linux.O{ .ACCMODE = .RDWR, .CREAT = true, .EXCL = true }), 0o600);
        if (global.poolFile >= 0) {
            _ = std.c.shm_unlink(@ptrCast(&shmName));
            break;
        }
    }
    std.posix.ftruncate(global.poolFile, @intCast(poolSize)) catch return error.ShmFileError;

    global.data = std.posix.mmap(null, @intCast(poolSize), std.posix.PROT.READ | std.posix.PROT.WRITE, @bitCast(std.posix.MAP{ .TYPE = .SHARED }), global.poolFile, 0) catch return error.CantCreatePool;
    global.pool = c.wl_shm_create_pool(global.shm, global.poolFile, poolSize);
    const index = 0;
    const offset = global.height * stride * index;
    global.buffer = c.wl_shm_pool_create_buffer(global.pool, offset, global.width, global.height, stride, c.WL_SHM_FORMAT_ARGB8888);
    _ = c.wl_buffer_add_listener(global.buffer, &bufferListener, null);
    std.log.warn("createBuffer done", .{});
}

fn destroyBuffer() common.PlatformError!void {
    std.log.warn("destroyBuffer", .{});
    if (global.buffer != null) {
        c.wl_buffer_destroy(global.buffer);
    }
    if (global.data.len > 0) {
        std.posix.munmap(global.data);
    }
    if (global.poolFile >= 0) {
        std.posix.close(global.poolFile);
    }
}

fn draw() common.PlatformError!void {
    std.log.warn("draw", .{});
    const scrollOffset = global.tempOffset % 8;
    for (0..@intCast(global.height)) |y| {
        for (0..@intCast(global.width)) |x| {
            const poolOffset = (y * @as(usize, @intCast(global.width)) + x) * 4;
            if (((x + scrollOffset) + (y + scrollOffset) / 8 * 8) % 16 < 8) {
                global.data[poolOffset + 0] = 0x0;
                global.data[poolOffset + 1] = 0x0;
                global.data[poolOffset + 2] = 0x0;
                global.data[poolOffset + 3] = 0x0;
            } else {
                global.data[poolOffset + 0] = 0x0;
                global.data[poolOffset + 1] = 0x80;
                global.data[poolOffset + 2] = 0xFF;
                global.data[poolOffset + 3] = 0xFF;
            }
        }
    }
    std.log.warn("draw done", .{});
}

const registryListener = c.wl_registry_listener{
    .global = registryGlobal,
    .global_remove = registryGlobalRemove,
};

const bufferListener = c.wl_buffer_listener{
    .release = bufferRelease,
};

const xdgBaseListener = c.xdg_wm_base_listener{
    .ping = xdgPing,
};

const xdgSurfaceListener = c.xdg_surface_listener{
    .configure = xdgSurfaceConfigure,
};

const frameListener = c.wl_callback_listener{
    .done = frameDone,
};

fn registryGlobal(data: ?*anyopaque, registry: ?*c.wl_registry, name: u32, interface: [*c]const u8, version: u32) callconv(.C) void {
    _ = data;
    std.log.warn("Registry call! interface = '{s}', version = {d}, name = {d}", .{ interface, version, name });

    if (std.mem.eql(u8, std.mem.span(interface), std.mem.span(c.wl_compositor_interface.name))) {
        global.compositor = @ptrCast(c.wl_registry_bind(registry, name, &c.wl_compositor_interface, 4));
    } else if (std.mem.eql(u8, std.mem.span(interface), std.mem.span(c.wl_shm_interface.name))) {
        global.shm = @ptrCast(c.wl_registry_bind(registry, name, &c.wl_shm_interface, 1));
    } else if (std.mem.eql(u8, std.mem.span(interface), std.mem.span(c.xdg_wm_base_interface.name))) {
        global.xdgBase = @ptrCast(c.wl_registry_bind(registry, name, &c.xdg_wm_base_interface, 1));
        _ = c.xdg_wm_base_add_listener(global.xdgBase, &xdgBaseListener, null);
    }
}

fn registryGlobalRemove(data: ?*anyopaque, registry: ?*c.wl_registry, name: u32) callconv(.C) void {
    _ = data;
    _ = registry;
    std.log.warn("Registry remove! name = {d}", .{name});
}

fn bufferRelease(data: ?*anyopaque, buffer: ?*c.wl_buffer) callconv(.C) void {
    _ = data;
    std.log.warn("bufferRelease", .{});
    c.wl_buffer_destroy(buffer);
}

fn xdgPing(data: ?*anyopaque, xdgBase: ?*c.xdg_wm_base, serial: u32) callconv(.C) void {
    _ = data;
    c.xdg_wm_base_pong(xdgBase, serial);
}

fn xdgSurfaceConfigure(data: ?*anyopaque, xdgSurface: ?*c.xdg_surface, serial: u32) callconv(.C) void {
    _ = data;
    std.log.warn("configure", .{});

    c.xdg_surface_ack_configure(xdgSurface, serial);

    destroyBuffer() catch |e| {
        std.log.warn("destroyBuffer error: {}", .{e});
    };
    createBuffer() catch |e| {
        std.log.warn("createBuffer error: {}", .{e});
    };

    draw() catch {};
    std.log.warn("1", .{});
    std.log.warn("global.buffer = {?}, global.surface = {?}", .{ global.buffer, global.surface });
    c.wl_surface_attach(global.surface, global.buffer, 0, 0);
    std.log.warn("2", .{});
    c.wl_surface_damage(global.surface, 0, 0, std.math.maxInt(i32), std.math.maxInt(i32));
    std.log.warn("3", .{});
    c.wl_surface_commit(global.surface);
    std.log.warn("configure done", .{});
}

fn frameDone(data: ?*anyopaque, callback: ?*c.wl_callback, time: u32) callconv(.C) void {
    _ = data;
    std.log.warn("frameDone", .{});

    c.wl_callback_destroy(callback);
    const frameCallback = c.wl_surface_frame(global.surface);
    _ = c.wl_callback_add_listener(frameCallback, &frameListener, null);

    if (time >= global.tempNextFrameTime) {
        global.tempNextFrameTime += 100;
        global.tempOffset += 1;
        draw() catch {};
        c.wl_surface_attach(global.surface, global.buffer, 0, 0);
        c.wl_surface_damage(global.surface, 0, 0, std.math.maxInt(i32), std.math.maxInt(i32));
        c.wl_surface_commit(global.surface);
    }
}
