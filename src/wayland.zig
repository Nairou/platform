const std = @import("std");
const lib = @import("lib.zig");
const gl = @import("zgl");
const assert = std.debug.assert;

pub const c = @cImport({
    @cInclude("wayland-client-core.h");
    @cInclude("wayland-client-protocol.h");
    @cInclude("xdg-shell-client-protocol.h");
    @cInclude("xkbcommon/xkbcommon.h");
    @cInclude("wayland-egl.h");
    @cInclude("EGL/egl.h");
    //@cDefine("EGL_EGLEXT_PROTOTYPES", {});
    @cInclude("EGL/eglext.h");
});

const global = struct {
    // Globals
    pub var display: *c.wl_display = undefined;
    pub var registry: *c.wl_registry = undefined;
    pub var compositor: *c.wl_compositor = undefined;
    pub var eglDisplay: c.EGLDisplay = undefined;
    pub var eglWindow: ?*c.wl_egl_window = null;
    pub var eglSurface: c.EGLSurface = undefined;
    pub var xdgBase: *c.xdg_wm_base = undefined;
    pub var seat: *c.wl_seat = undefined;
    pub var seatCapabilities: struct {
        pointer: bool = false,
        keyboard: bool = false,
    } = .{};
    const xkb = struct {
        pub var context: ?*c.xkb_context = null;
        pub var keymap: ?*c.xkb_keymap = null;
        pub var state: ?*c.xkb_state = null;
    };
    pub var pointer: ?*c.wl_pointer = null;
    pub var keyboard: ?*c.wl_keyboard = null;

    // Window (need to move)
    pub var shouldClose: bool = false;
    pub var width: i32 = 200;
    pub var height: i32 = 100;
    pub var surface: ?*c.wl_surface = null;
    pub var xdgSurface: *c.xdg_surface = undefined;
    pub var xdgTopLevel: *c.xdg_toplevel = undefined;

    // Temporary testing
    pub var tempOffset: u32 = 0;
    pub var tempNextFrameTime: u32 = 0;
};

fn init(allocator: std.mem.Allocator) lib.PlatformError!void {
    _ = allocator;

    std.log.warn("init wayland", .{});

    global.display = c.wl_display_connect(null) orelse return error.FailedToConnect;
    global.registry = c.wl_display_get_registry(global.display) orelse return error.FailedToConnect;
    _ = c.wl_registry_add_listener(global.registry, &registryListener, null);
    global.xkb.context = c.xkb_context_new(c.XKB_CONTEXT_NO_FLAGS);
    _ = c.wl_display_roundtrip(global.display);

    var eglExtPlatformBase: bool = false;
    var eglExtPlatformWayland: bool = false;

    const eglQueryString = c.eglQueryString(c.EGL_NO_DISPLAY, c.EGL_EXTENSIONS);
    var it = std.mem.splitScalar(u8, std.mem.span(eglQueryString), ' ');
    while (it.next()) |value| {
        std.log.warn("eglQueryString value: '{s}'", .{value});
        if (std.mem.eql(u8, value, "EGL_EXT_platform_base")) {
            eglExtPlatformBase = true;
        } else if (std.mem.eql(u8, value, "EGL_EXT_platform_wayland")) {
            eglExtPlatformWayland = true;
        }
    }

    if (eglExtPlatformBase and eglExtPlatformWayland) {
        global.eglDisplay = c.eglGetPlatformDisplay(c.EGL_PLATFORM_WAYLAND_EXT, global.display, null);
    } else {
        global.eglDisplay = c.eglGetDisplay(global.display);
    }
    if (global.eglDisplay == c.EGL_NO_DISPLAY) {
        return error.EglUnavailable;
    }

    var eglMajor: i32 = 0;
    var eglMinor: i32 = 0;
    if (c.eglInitialize(global.eglDisplay, &eglMajor, &eglMinor) == 0) {
        return error.EglUnavailable;
    }
    std.log.warn("EGL version {d}.{d}", .{ eglMajor, eglMinor });
    if (c.eglBindAPI(c.EGL_OPENGL_API) == 0) {
        return error.EglUnavailable;
    }

    const eglConfigAttributes = [_]u32{
        c.EGL_SURFACE_TYPE,
        c.EGL_WINDOW_BIT,
        c.EGL_RED_SIZE,
        8,
        c.EGL_GREEN_SIZE,
        8,
        c.EGL_BLUE_SIZE,
        8,
        c.EGL_CONFIG_CAVEAT,
        c.EGL_NONE,
        c.EGL_RENDERABLE_TYPE,
        c.EGL_OPENGL_BIT,
        c.EGL_NONE,
    };
    var configList: [100]c.EGLConfig = undefined;
    var configCount: i32 = 0;
    if (c.eglChooseConfig(global.eglDisplay, @ptrCast(&eglConfigAttributes), &configList, configList.len, &configCount) == 0) {
        return error.EglUnavailable;
    }
    std.log.warn("EGL configs: count = {d}", .{configCount});

    const eglContextAttributes = [_]u32{
        c.EGL_CONTEXT_MAJOR_VERSION,
        4,
        c.EGL_CONTEXT_MINOR_VERSION,
        5,
        c.EGL_CONTEXT_OPENGL_PROFILE_MASK,
        c.EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT,
        c.EGL_CONTEXT_OPENGL_FORWARD_COMPATIBLE,
        c.EGL_TRUE,
        c.EGL_NONE,
    };
    const eglContext = c.eglCreateContext(global.eglDisplay, configList[0], c.EGL_NO_CONTEXT, @ptrCast(&eglContextAttributes)) orelse return error.EglUnavailable;

    // Window
    {
        global.surface = c.wl_compositor_create_surface(global.compositor) orelse return error.FailedToConnect;
        _ = c.wl_surface_add_listener(global.surface, &surfaceListener, null);
        global.xdgSurface = c.xdg_wm_base_get_xdg_surface(global.xdgBase, global.surface) orelse return error.FailedToConnect;
        _ = c.xdg_surface_add_listener(global.xdgSurface, &xdgSurfaceListener, null);
        global.xdgTopLevel = c.xdg_surface_get_toplevel(global.xdgSurface) orelse return error.FailedToConnect;
        _ = c.xdg_toplevel_add_listener(global.xdgTopLevel, &xdgToplevelListener, null);
        c.xdg_toplevel_set_app_id(global.xdgTopLevel, "platform");
        c.xdg_toplevel_set_title(global.xdgTopLevel, "Sample Title");
        c.wl_surface_commit(global.surface);

        const frameCallback = c.wl_surface_frame(global.surface);
        _ = c.wl_callback_add_listener(frameCallback, &frameListener, null);

        global.eglWindow = c.wl_egl_window_create(global.surface, global.width, global.height) orelse return error.EglUnavailable;
        global.eglSurface = c.eglCreatePlatformWindowSurface(global.eglDisplay, configList[0], global.eglWindow, null) orelse return error.EglUnavailable;
        if (c.eglMakeCurrent(global.eglDisplay, global.eglSurface, global.eglSurface, eglContext) == 0) {
            return error.EglUnavailable;
        }
    }

    gl.loadExtensions(void, glGetProcAddress) catch return error.CantLoadGlExtensions;

    while (!global.shouldClose) {
        _ = c.wl_display_dispatch(global.display);
        draw() catch {};

        _ = c.eglSwapBuffers(global.eglDisplay, global.eglSurface);
    }
}

pub fn glGetProcAddress(comptime _: type, proc: [:0]const u8) ?*const anyopaque {
    return c.eglGetProcAddress(proc);
}

test "init" {
    _ = try init(std.testing.allocator);
}

pub fn deinit() void {
    c.xkb_keymap_unref(global.xkb.keymap);
    c.xkb_state_unref(global.xkb.state);

    if (global.keyboard) |keyboard| {
        c.wl_keyboard_release(keyboard);
    }
    if (global.pointer) |pointer| {
        c.wl_pointer_release(pointer);
    }
    c.wl_seat_release(global.seat);
    c.wl_surface_destroy(global.surface);
    c.wl_egl_window_destroy(global.eglWindow);
    c.eglTerminate(global.eglDisplay);
    c.wl_display_disconnect(global.display);
}

fn draw() lib.PlatformError!void {
    gl.clearColor(1, 0, 0, 1.0);
    gl.clear(.{ .color = true, .depth = true, .stencil = false });
}

const registryListener = c.wl_registry_listener{
    .global = registryGlobal,
    .global_remove = registryGlobalRemove,
};

fn registryGlobal(data: ?*anyopaque, registry: ?*c.wl_registry, name: u32, interface: [*c]const u8, version: u32) callconv(.C) void {
    _ = data;
    _ = version;

    if (std.mem.eql(u8, std.mem.span(interface), std.mem.span(c.wl_compositor_interface.name))) {
        global.compositor = @ptrCast(c.wl_registry_bind(registry, name, &c.wl_compositor_interface, 4));
    } else if (std.mem.eql(u8, std.mem.span(interface), std.mem.span(c.wl_seat_interface.name))) {
        global.seat = @ptrCast(c.wl_registry_bind(registry, name, &c.wl_seat_interface, 7));
        _ = c.wl_seat_add_listener(global.seat, &seatListener, null);
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

const bufferListener = c.wl_buffer_listener{
    .release = bufferRelease,
};

fn bufferRelease(data: ?*anyopaque, buffer: ?*c.wl_buffer) callconv(.C) void {
    _ = data;
    std.log.warn("wl_buffer.release", .{});
    c.wl_buffer_destroy(buffer);
}

const xdgBaseListener = c.xdg_wm_base_listener{
    .ping = xdgPing,
};

fn xdgPing(data: ?*anyopaque, xdgBase: ?*c.xdg_wm_base, serial: u32) callconv(.C) void {
    _ = data;
    c.xdg_wm_base_pong(xdgBase, serial);
}

const surfaceListener = c.wl_surface_listener{
    .enter = surfaceEnter,
    .leave = surfaceLeave,
    .preferred_buffer_scale = surfacePreferredBufferScale,
    .preferred_buffer_transform = surfacePreferredBufferTransform,
};

fn surfaceEnter(data: ?*anyopaque, surface: ?*c.wl_surface, output: ?*c.wl_output) callconv(.C) void {
    _ = data;
    _ = surface;
    _ = output;
    std.log.warn("wl_surface.enter", .{});
}

fn surfaceLeave(data: ?*anyopaque, surface: ?*c.wl_surface, output: ?*c.wl_output) callconv(.C) void {
    _ = data;
    _ = surface;
    _ = output;
    std.log.warn("wl_surface.leave", .{});
}

fn surfacePreferredBufferScale(data: ?*anyopaque, surface: ?*c.wl_surface, factor: i32) callconv(.C) void {
    _ = data;
    _ = surface;
    std.log.warn("wl_surface.preferred_buffer_scale: factor = {d}", .{factor});
}

fn surfacePreferredBufferTransform(data: ?*anyopaque, surface: ?*c.wl_surface, transform: u32) callconv(.C) void {
    _ = data;
    _ = surface;
    std.log.warn("wl_surface.preferred_buffer_transform: transform = {d}", .{transform});
}

const xdgSurfaceListener = c.xdg_surface_listener{
    .configure = xdgSurfaceConfigure,
};

fn xdgSurfaceConfigure(data: ?*anyopaque, xdgSurface: ?*c.xdg_surface, serial: u32) callconv(.C) void {
    _ = data;
    std.log.warn("xdg_surface.configure", .{});

    c.xdg_surface_ack_configure(xdgSurface, serial);

    // TODO: ???

    draw() catch {};
    c.wl_surface_commit(global.surface);
}

const xdgToplevelListener = c.xdg_toplevel_listener{
    .close = xdgToplevelClose,
    .configure = xdgToplevelConfigure,
};

fn xdgToplevelClose(data: ?*anyopaque, xdgToplevel: ?*c.xdg_toplevel) callconv(.C) void {
    _ = data;
    _ = xdgToplevel;

    std.log.warn("xdgToplevelClose", .{});
    global.shouldClose = true;
}

fn xdgToplevelConfigure(data: ?*anyopaque, xdgToplevel: ?*c.xdg_toplevel, width: i32, height: i32, states: [*c]c.wl_array) callconv(.C) void {
    _ = data;
    _ = xdgToplevel;

    std.log.warn("xdg_toplevel.configure: width = {d}, height = {d}, states = [{any}]", .{ width, height, states });
    if (width != 0 and height != 0) {
        global.width = width;
        global.height = height;

        // TODO: ???
    }
}

const frameListener = c.wl_callback_listener{
    .done = frameDone,
};

fn frameDone(data: ?*anyopaque, callback: ?*c.wl_callback, time: u32) callconv(.C) void {
    _ = data;

    c.wl_callback_destroy(callback);
    const frameCallback = c.wl_surface_frame(global.surface);
    _ = c.wl_callback_add_listener(frameCallback, &frameListener, null);

    if (time >= global.tempNextFrameTime) {
        global.tempNextFrameTime += 100;
        global.tempOffset += 1;
        draw() catch {};
    }
}

const seatListener = c.wl_seat_listener{
    .capabilities = seatCapabilities,
    .name = seatName,
};

fn seatCapabilities(data: ?*anyopaque, seat: ?*c.wl_seat, capability: u32) callconv(.C) void {
    _ = data;
    _ = seat;

    std.log.warn("Seat capability: {d}", .{capability});
    const usePointer = (capability & c.WL_SEAT_CAPABILITY_POINTER) != 0;
    const useKeyboard = (capability & c.WL_SEAT_CAPABILITY_KEYBOARD) != 0;

    if (usePointer and global.pointer == null) {
        std.log.warn("seat: add pointer", .{});
        global.pointer = c.wl_seat_get_pointer(global.seat);
        _ = c.wl_pointer_add_listener(global.pointer, &pointerListener, null);
    } else if (!usePointer and global.pointer != null) {
        std.log.warn("seat: remove pointer", .{});
        c.wl_pointer_release(global.pointer);
        global.pointer = null;
    }

    if (useKeyboard and global.keyboard == null) {
        std.log.warn("seat: add keyboard", .{});
        global.keyboard = c.wl_seat_get_keyboard(global.seat);
        _ = c.wl_keyboard_add_listener(global.keyboard, &keyboardListener, null);
    } else if (!useKeyboard and global.keyboard != null) {
        std.log.warn("seat: remove keyboard", .{});
        c.wl_keyboard_release(global.keyboard);
        global.keyboard = null;
    }

    global.seatCapabilities = .{
        .pointer = usePointer,
        .keyboard = useKeyboard,
    };
}

fn seatName(data: ?*anyopaque, seat: ?*c.wl_seat, name: [*c]const u8) callconv(.C) void {
    _ = data;
    _ = seat;

    std.log.warn("Seat name: {s}", .{name});
}

const pointerListener = c.wl_pointer_listener{
    .axis = pointerAxis,
    .axis_discrete = pointerAxisDiscrete,
    .axis_relative_direction = pointerAxisRelativeDirection,
    .axis_source = pointerAxisSource,
    .axis_stop = pointerAxisStop,
    .axis_value120 = pointerAxisValue120,
    .button = pointerButton,
    .enter = pointerEnter,
    .frame = pointerFrame,
    .leave = pointerLeave,
    .motion = pointerMotion,
};

fn pointerAxis(data: ?*anyopaque, pointer: ?*c.wl_pointer, time: u32, axis: u32, value: c.wl_fixed_t) callconv(.C) void {
    _ = data;
    _ = pointer;
    std.log.warn("wl_pointer.axis: time = {d}, axis = {d}, value = {d}", .{ time, axis, value });
}

fn pointerAxisDiscrete(data: ?*anyopaque, pointer: ?*c.wl_pointer, axis: u32, discrete: i32) callconv(.C) void {
    _ = data;
    _ = pointer;
    std.log.warn("wl_pointer.axis_discrete: axis = {d}, discrete = {d}", .{ axis, discrete });
}

fn pointerAxisRelativeDirection(data: ?*anyopaque, pointer: ?*c.wl_pointer, axis: u32, direction: u32) callconv(.C) void {
    _ = data;
    _ = pointer;
    std.log.warn("wl_pointer.axis_relative_direction: axis = {d}, direction = {d}", .{ axis, direction });
}

fn pointerAxisSource(data: ?*anyopaque, pointer: ?*c.wl_pointer, source: u32) callconv(.C) void {
    _ = data;
    _ = pointer;
    std.log.warn("wl_pointer.axis_source: source = {d}", .{source});
}

fn pointerAxisStop(data: ?*anyopaque, pointer: ?*c.wl_pointer, time: u32, axis: u32) callconv(.C) void {
    _ = data;
    _ = pointer;
    std.log.warn("wl_pointer.axis_stop: time = {d}, axis = {d}", .{ time, axis });
}

fn pointerAxisValue120(data: ?*anyopaque, pointer: ?*c.wl_pointer, axis: u32, value120: i32) callconv(.C) void {
    _ = data;
    _ = pointer;
    std.log.warn("wl_pointer.axis_value120: axis = {d}, value120 = {d}", .{ axis, value120 });
}

fn pointerButton(data: ?*anyopaque, pointer: ?*c.wl_pointer, serial: u32, time: u32, button: u32, state: u32) callconv(.C) void {
    _ = data;
    _ = pointer;
    std.log.warn("wl_pointer.button: serial = {d}, time = {d}, button = {d}, state = {d}", .{ serial, time, button, state });
}

fn pointerEnter(data: ?*anyopaque, pointer: ?*c.wl_pointer, serial: u32, surface: ?*c.wl_surface, x: c.wl_fixed_t, y: c.wl_fixed_t) callconv(.C) void {
    _ = data;
    _ = pointer;
    _ = surface;
    std.log.warn("wl_pointer.enter: serial = {d}, x = {}, y = {}", .{ serial, x, y });
}

fn pointerFrame(data: ?*anyopaque, pointer: ?*c.wl_pointer) callconv(.C) void {
    _ = data;
    _ = pointer;
    std.log.warn("wl_pointer.frame", .{});
}

fn pointerLeave(data: ?*anyopaque, pointer: ?*c.wl_pointer, serial: u32, surface: ?*c.wl_surface) callconv(.C) void {
    _ = data;
    _ = pointer;
    _ = surface;
    std.log.warn("wl_pointer.leave: serial = {d}", .{serial});
}

fn pointerMotion(data: ?*anyopaque, pointer: ?*c.wl_pointer, time: u32, x: c.wl_fixed_t, y: c.wl_fixed_t) callconv(.C) void {
    _ = data;
    _ = pointer;
    std.log.warn("wl_pointer.motion: time = {d}, x = {d}, y = {d}", .{ time, std.math.round(@as(f32, @floatFromInt(x)) / 255), std.math.round(@as(f32, @floatFromInt(y)) / 255) });
}

const keyboardListener = c.wl_keyboard_listener{
    .enter = keyboardEnter,
    .key = keyboardKey,
    .keymap = keyboardKeymap,
    .leave = keyboardLeave,
    .modifiers = keyboardModifiers,
    .repeat_info = keyboardRepeatInfo,
};

fn keyboardEnter(data: ?*anyopaque, keyboard: ?*c.wl_keyboard, serial: u32, surface: ?*c.wl_surface, keys: [*c]c.wl_array) callconv(.C) void {
    _ = data;
    _ = keyboard;
    _ = surface;
    const keysArray: *c.wl_array = @ptrCast(keys);
    std.log.warn("wl_keyboard.enter: serial = {d}, keys = {d}", .{ serial, keysArray.size });
}

fn keyboardKey(data: ?*anyopaque, keyboard: ?*c.wl_keyboard, serial: u32, time: u32, key: u32, state: u32) callconv(.C) void {
    _ = data;
    _ = keyboard;
    const keycode = key + 8;
    const sym = c.xkb_state_key_get_one_sym(global.xkb.state, keycode);
    std.log.warn("wl_keyboard.key: serial = {d}, time = {d}, key = {d}, sym = {d}, state = {d}", .{ serial, time, key, sym, state });
}

fn keyboardKeymap(data: ?*anyopaque, keyboard: ?*c.wl_keyboard, format: u32, fd: i32, size: u32) callconv(.C) void {
    _ = data;
    _ = keyboard;
    assert(format == c.WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1);
    c.xkb_keymap_unref(global.xkb.keymap);
    const shm = std.posix.mmap(null, size, std.posix.PROT.READ, @bitCast(std.posix.MAP{ .TYPE = .PRIVATE }), fd, 0) catch unreachable;
    global.xkb.keymap = c.xkb_keymap_new_from_string(global.xkb.context, shm.ptr, c.XKB_KEYMAP_FORMAT_TEXT_V1, c.XKB_KEYMAP_COMPILE_NO_FLAGS);
    std.posix.munmap(shm);
    std.posix.close(fd);
    c.xkb_state_unref(global.xkb.state);
    global.xkb.state = c.xkb_state_new(global.xkb.keymap);
}

fn keyboardLeave(data: ?*anyopaque, keyboard: ?*c.wl_keyboard, serial: u32, surface: ?*c.wl_surface) callconv(.C) void {
    _ = data;
    _ = keyboard;
    _ = surface;
    std.log.warn("wl_keyboard.leave: serial = {d}", .{serial});
}

fn keyboardModifiers(data: ?*anyopaque, keyboard: ?*c.wl_keyboard, serial: u32, depressed: u32, latched: u32, locked: u32, group: u32) callconv(.C) void {
    _ = data;
    _ = keyboard;
    _ = serial;
    _ = c.xkb_state_update_mask(global.xkb.state, depressed, latched, locked, 0, 0, group);
}

fn keyboardRepeatInfo(data: ?*anyopaque, keyboard: ?*c.wl_keyboard, rate: i32, delay: i32) callconv(.C) void {
    _ = data;
    _ = keyboard;
    std.log.warn("wl_keyboard.repeat_info: = rate = {d}, delay = {d}", .{ rate, delay });
}
