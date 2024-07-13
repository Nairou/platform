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
    pub var surface: *c.wl_surface = undefined;
    pub var xdgSurface: *c.xdg_surface = undefined;
    pub var xdgTopLevel: *c.xdg_toplevel = undefined;
    pub var buffer: *c.wl_buffer = undefined;
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
    c.xdg_toplevel_set_title(global.xdgTopLevel, "Sample Title");
    c.wl_surface_commit(global.surface);

    const tempWidth = 200;
    const tempHeight = 100;
    const stride = tempWidth * 4;
    const shmPoolSize = tempHeight * stride * 2;

    var shmName: [100]u8 = undefined;
    const prefix = "/platform-shm-";
    std.mem.copyForwards(u8, &shmName, prefix);
    const rngLen = 8;
    const fd = blk: for (0..100) |_| {
        var currentTime = std.time.nanoTimestamp();
        for (0..rngLen) |i| {
            shmName[prefix.len + i] = 'A' + @as(u8, @intCast(currentTime & 15)) + @as(u8, @intCast(currentTime & 16)) * 2;
            currentTime >>= 5;
        }
        shmName[prefix.len + rngLen] = 0;
        std.log.warn("shm: '{s}'", .{shmName});
        const fd = std.c.shm_open(@ptrCast(&shmName), @bitCast(std.os.linux.O{ .ACCMODE = .RDWR, .CREAT = true, .EXCL = true }), 0o600);
        if (fd >= 0) {
            _ = std.c.shm_unlink(@ptrCast(&shmName));
            break :blk fd;
        }
    } else return error.ShmFileExists;
    std.posix.ftruncate(fd, shmPoolSize) catch return error.ShmFileError;

    const poolData = std.posix.mmap(null, shmPoolSize, std.posix.PROT.READ | std.posix.PROT.WRITE, @bitCast(std.posix.MAP{ .TYPE = .SHARED }), fd, 0) catch return error.CantCreatePool;
    const shmPool = c.wl_shm_create_pool(global.shm, fd, shmPoolSize) orelse return error.CantCreatePool;
    const index = 0;
    const offset = tempHeight * stride * index;
    global.buffer = c.wl_shm_pool_create_buffer(shmPool, offset, tempWidth, tempHeight, stride, c.WL_SHM_FORMAT_ARGB8888) orelse return error.CantCreateBuffer;
    //@memset(poolData, 0xFFFF8000) orelse return error.CantCreatePool;
    var poolIndex: usize = 0;
    while (poolIndex < shmPoolSize) {
        poolData[poolIndex + 0] = 0x0;
        poolData[poolIndex + 1] = 0x80;
        poolData[poolIndex + 2] = 0xFF;
        poolData[poolIndex + 3] = 0x80;
        poolIndex += 4;
    }
    std.posix.munmap(poolData);
    _ = c.wl_buffer_add_listener(global.buffer, &bufferListener, null);

    while (c.wl_display_dispatch(global.display) != 0) {}

    c.wl_buffer_destroy(global.buffer);
    c.wl_surface_destroy(global.surface);
    c.wl_display_disconnect(global.display);
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
    c.wl_buffer_destroy(buffer);
}

fn xdgPing(data: ?*anyopaque, xdgBase: ?*c.xdg_wm_base, serial: u32) callconv(.C) void {
    _ = data;
    c.xdg_wm_base_pong(xdgBase, serial);
}

fn xdgSurfaceConfigure(data: ?*anyopaque, xdgSurface: ?*c.xdg_surface, serial: u32) callconv(.C) void {
    _ = data;

    c.xdg_surface_ack_configure(xdgSurface, serial);

    c.wl_surface_attach(global.surface, global.buffer, 0, 0);
    c.wl_surface_damage(global.surface, 0, 0, std.math.maxInt(i32), std.math.maxInt(i32));
    c.wl_surface_commit(global.surface);
}
