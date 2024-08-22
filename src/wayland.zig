const std = @import("std");
const Platform = @import("lib.zig");
const BackendError = @import("lib.zig").BackendError;
const Window = @import("lib.zig").Window;
const WindowId = @import("lib.zig").WindowId;
const assert = std.debug.assert;

const c = @cImport({
    @cInclude("wayland-client-core.h");
    @cInclude("wayland-client-protocol.h");
    @cInclude("xdg-shell-client-protocol.h");
    @cInclude("xkbcommon/xkbcommon.h");
    @cInclude("wayland-egl.h");
    @cInclude("EGL/egl.h");
    //@cDefine("EGL_EGLEXT_PROTOTYPES", {});
    @cInclude("EGL/eglext.h");
});

compositor: ?*c.wl_compositor = null,
display: *c.wl_display = undefined,
xdgBase: *c.xdg_wm_base = undefined,
seat: *c.wl_seat = undefined,
seatCapabilities: struct {
    pointer: bool = false,
    keyboard: bool = false,
} = .{},
pointer: ?*c.wl_pointer = null,
keyboard: ?*c.wl_keyboard = null,
egl: struct {
    context: c.EGLContext = undefined,
    config: c.EGLConfig = undefined,
    display: c.EGLDisplay = undefined,
} = .{},
xkb: struct {
    context: ?*c.xkb_context = null,
    keymap: ?*c.xkb_keymap = null,
    state: ?*c.xkb_state = null,
} = .{},

dispatch: struct {
    deinit: *const fn (backend: *Wayland) void,
},

pub const WindowData = struct {
    wlSurface: ?*c.wl_surface = undefined,
    xdgSurface: *c.xdg_surface = undefined,
    xdgTopLevel: *c.xdg_toplevel = undefined,
    eglWindow: *c.wl_egl_window = undefined,
    eglSurface: c.EGLSurface = undefined,
};

const Wayland = @This();

pub fn init(backend: *Wayland, allocator: std.mem.Allocator) BackendError!void {
    _ = allocator;

    std.log.debug("init wayland", .{});

    backend.display = c.wl_display_connect(null) orelse return error.FailedToConnect;
    const registry = c.wl_display_get_registry(backend.display) orelse return error.FailedToConnect;
    _ = c.wl_registry_add_listener(registry, &registryListener, backend);
    backend.xkb.context = c.xkb_context_new(c.XKB_CONTEXT_NO_FLAGS);
    _ = c.wl_display_roundtrip(backend.display);

    var eglExtPlatformBase: bool = false;
    var eglExtPlatformWayland: bool = false;

    const eglQueryString = c.eglQueryString(c.EGL_NO_DISPLAY, c.EGL_EXTENSIONS);
    var it = std.mem.splitScalar(u8, std.mem.span(eglQueryString), ' ');
    while (it.next()) |value| {
        std.log.debug("eglQueryString value: '{s}'", .{value});
        if (std.mem.eql(u8, value, "EGL_EXT_platform_base")) {
            eglExtPlatformBase = true;
        } else if (std.mem.eql(u8, value, "EGL_EXT_platform_wayland")) {
            eglExtPlatformWayland = true;
        }
    }

    if (eglExtPlatformBase and eglExtPlatformWayland) {
        backend.egl.display = c.eglGetPlatformDisplay(c.EGL_PLATFORM_WAYLAND_EXT, backend.display, null);
    } else {
        backend.egl.display = c.eglGetDisplay(backend.display);
    }
    assert(c.eglGetError() == c.EGL_SUCCESS);
    if (backend.egl.display == c.EGL_NO_DISPLAY) {
        return error.EglUnavailable;
    }

    var eglMajor: i32 = 0;
    var eglMinor: i32 = 0;
    if (c.eglInitialize(backend.egl.display, &eglMajor, &eglMinor) == 0) {
        return error.EglUnavailable;
    }
    assert(c.eglGetError() == c.EGL_SUCCESS);
    std.log.debug("EGL version {d}.{d}", .{ eglMajor, eglMinor });
    if (c.eglBindAPI(c.EGL_OPENGL_API) == 0) {
        return error.EglUnavailable;
    }
    assert(c.eglGetError() == c.EGL_SUCCESS);

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
    // TODO: Sort through available configs to find the best match
    var configList: [100]c.EGLConfig = undefined;
    var configCount: i32 = 0;
    //if (c.eglChooseConfig(backend.egl.display, @ptrCast(&eglConfigAttributes), &backend.egl.config, 1, null) == 0) {
    if (c.eglChooseConfig(backend.egl.display, @ptrCast(&eglConfigAttributes), &configList, configList.len, &configCount) == 0) {
        return error.EglUnavailable;
    }
    assert(c.eglGetError() == c.EGL_SUCCESS);
    std.log.debug("EGL config count: {d}", .{configCount});
    backend.egl.config = configList[0];

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
    backend.egl.context = c.eglCreateContext(backend.egl.display, backend.egl.config, c.EGL_NO_CONTEXT, @ptrCast(&eglContextAttributes)) orelse return error.EglUnavailable;
    assert(c.eglGetError() == c.EGL_SUCCESS);

    std.log.debug("init success", .{});
}

test "init" {
    //var backend: Wayland = undefined;
    //_ = try backend.init(std.testing.allocator);
    //defer backend.deinit();
}

pub fn deinit(backend: *Wayland) void {
    if (backend.xkb.keymap) |keymap| {
        c.xkb_keymap_unref(keymap);
    }
    if (backend.xkb.state) |state| {
        c.xkb_state_unref(state);
    }

    if (backend.keyboard) |keyboard| {
        c.wl_keyboard_release(keyboard);
    }
    if (backend.pointer) |pointer| {
        c.wl_pointer_release(pointer);
    }
    c.wl_seat_release(backend.seat);
    _ = c.eglTerminate(backend.egl.display);
    c.wl_display_disconnect(backend.display);
}

pub fn processEvents(backend: *Wayland, wait: bool) void {
    _ = wait;
    _ = c.wl_display_dispatch(backend.display);
}

pub fn getProcAddress(backend: *Wayland, proc: [:0]const u8) ?*const anyopaque {
    _ = backend;
    return c.eglGetProcAddress(proc);
}

pub fn initWindow(backend: *Wayland, window: *Window) !void {
    std.log.debug("Window: {any}", .{window});
    window.backend = .{ .wayland = WindowData{} };
    window.backend.wayland.wlSurface = c.wl_compositor_create_surface(backend.compositor) orelse return error.FailedToConnect;
    _ = c.wl_surface_add_listener(window.backend.wayland.wlSurface, &surfaceListener, window);
    window.backend.wayland.xdgSurface = c.xdg_wm_base_get_xdg_surface(backend.xdgBase, window.backend.wayland.wlSurface) orelse return error.FailedToConnect;
    _ = c.xdg_surface_add_listener(window.backend.wayland.xdgSurface, &xdgSurfaceListener, window);
    window.backend.wayland.xdgTopLevel = c.xdg_surface_get_toplevel(window.backend.wayland.xdgSurface) orelse return error.FailedToConnect;
    _ = c.xdg_toplevel_add_listener(window.backend.wayland.xdgTopLevel, &xdgToplevelListener, window);
    c.xdg_toplevel_set_app_id(window.backend.wayland.xdgTopLevel, "platform");
    c.xdg_toplevel_set_title(window.backend.wayland.xdgTopLevel, "Sample Title");
    c.wl_surface_commit(window.backend.wayland.wlSurface);

    const frameCallback = c.wl_surface_frame(window.backend.wayland.wlSurface);
    _ = c.wl_callback_add_listener(frameCallback, &frameListener, window);

    std.log.debug("Window width = {d}, height = {d}", .{ window.width, window.height });
    window.backend.wayland.eglWindow = c.wl_egl_window_create(window.backend.wayland.wlSurface, @intCast(window.width), @intCast(window.height)) orelse return error.EglUnavailable;
    window.backend.wayland.eglSurface = c.eglCreatePlatformWindowSurface(backend.egl.display, backend.egl.config, window.backend.wayland.eglWindow, null) orelse return error.EglUnavailable;
    assert(c.eglGetError() == c.EGL_SUCCESS);
    if (c.eglMakeCurrent(backend.egl.display, window.backend.wayland.eglSurface, window.backend.wayland.eglSurface, backend.egl.context) == 0) {
        return error.EglUnavailable;
    }
    assert(c.eglGetError() == c.EGL_SUCCESS);
}

pub fn deinitWindow(window: *Window) void {
    c.wl_surface_destroy(window.backend.wayland.wlSurface);
    c.wl_egl_window_destroy(window.backend.wayland.eglWindow);
}

pub fn swapWindowBuffer(backend: *Wayland, window: *Window) void {
    // TODO: Return error?
    _ = c.eglSwapBuffers(backend.egl.display, window.backend.wayland.eglSurface);
    assert(c.eglGetError() == c.EGL_SUCCESS);
    //c.wl_surface_commit(window.backend.wayland.wlSurface);
}

// ----------

const registryListener = c.wl_registry_listener{
    .global = registryGlobal,
    .global_remove = registryGlobalRemove,
};

fn registryGlobal(data: ?*anyopaque, registry: ?*c.wl_registry, name: u32, interface: [*c]const u8, version: u32) callconv(.C) void {
    _ = version;
    var backend: *Wayland = @alignCast(@ptrCast(data));
    if (std.mem.eql(u8, std.mem.span(interface), std.mem.span(c.wl_compositor_interface.name))) {
        backend.compositor = @ptrCast(c.wl_registry_bind(registry, name, &c.wl_compositor_interface, 4));
    } else if (std.mem.eql(u8, std.mem.span(interface), std.mem.span(c.wl_seat_interface.name))) {
        backend.seat = @ptrCast(c.wl_registry_bind(registry, name, &c.wl_seat_interface, 7));
        _ = c.wl_seat_add_listener(backend.seat, &seatListener, backend);
    } else if (std.mem.eql(u8, std.mem.span(interface), std.mem.span(c.xdg_wm_base_interface.name))) {
        backend.xdgBase = @ptrCast(c.wl_registry_bind(registry, name, &c.xdg_wm_base_interface, 1));
        _ = c.xdg_wm_base_add_listener(backend.xdgBase, &xdgBaseListener, backend);
    }
}

fn registryGlobalRemove(data: ?*anyopaque, registry: ?*c.wl_registry, name: u32) callconv(.C) void {
    _ = data;
    _ = registry;
    std.log.debug("Registry remove! name = {d}", .{name});
}

const xdgBaseListener = c.xdg_wm_base_listener{
    .ping = xdgPing,
};

fn xdgPing(data: ?*anyopaque, xdgBase: ?*c.xdg_wm_base, serial: u32) callconv(.C) void {
    _ = data;
    std.log.debug("xdg_wm_ping", .{});
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
    std.log.debug("wl_surface.enter", .{});
}

fn surfaceLeave(data: ?*anyopaque, surface: ?*c.wl_surface, output: ?*c.wl_output) callconv(.C) void {
    _ = data;
    _ = surface;
    _ = output;
    std.log.debug("wl_surface.leave", .{});
}

fn surfacePreferredBufferScale(data: ?*anyopaque, surface: ?*c.wl_surface, factor: i32) callconv(.C) void {
    _ = data;
    _ = surface;
    std.log.debug("wl_surface.preferred_buffer_scale: factor = {d}", .{factor});
}

fn surfacePreferredBufferTransform(data: ?*anyopaque, surface: ?*c.wl_surface, transform: u32) callconv(.C) void {
    _ = data;
    _ = surface;
    std.log.debug("wl_surface.preferred_buffer_transform: transform = {d}", .{transform});
}

const xdgSurfaceListener = c.xdg_surface_listener{
    .configure = xdgSurfaceConfigure,
};

fn xdgSurfaceConfigure(data: ?*anyopaque, xdgSurface: ?*c.xdg_surface, serial: u32) callconv(.C) void {
    std.log.debug("xdg_surface.configure", .{});

    c.xdg_surface_ack_configure(xdgSurface, serial);

    // TODO: ???
    const window: *Window = @alignCast(@ptrCast(data));
    c.wl_surface_commit(window.backend.wayland.wlSurface);
}

const xdgToplevelListener = c.xdg_toplevel_listener{
    .close = xdgToplevelClose,
    .configure = xdgToplevelConfigure,
};

fn xdgToplevelClose(data: ?*anyopaque, xdgToplevel: ?*c.xdg_toplevel) callconv(.C) void {
    _ = xdgToplevel;

    const window: *Window = @alignCast(@ptrCast(data));
    std.log.debug("xdgToplevelClose", .{});
    Platform.writeEvent(.{ .window_close = .{ .window = window.id } });
}

fn xdgToplevelConfigure(data: ?*anyopaque, xdgToplevel: ?*c.xdg_toplevel, width: i32, height: i32, states: [*c]c.wl_array) callconv(.C) void {
    _ = xdgToplevel;

    const window: *Window = @alignCast(@ptrCast(data));
    std.log.debug("xdg_toplevel.configure: width = {d}, height = {d}, states = [{any}]", .{ width, height, states });
    if (width != 0 and height != 0) {
        window.width = @intCast(width);
        window.height = @intCast(height);
        Platform.writeEvent(.{ .window_size = .{ .window = window.id, .width = window.width, .height = window.height } });

        c.wl_egl_window_resize(window.backend.wayland.eglWindow, width, height, 0, 0);
        c.wl_surface_commit(window.backend.wayland.wlSurface);
    }
}

const frameListener = c.wl_callback_listener{
    .done = frameDone,
};

fn frameDone(data: ?*anyopaque, callback: ?*c.wl_callback, time: u32) callconv(.C) void {
    _ = time;
    const window: *Window = @alignCast(@ptrCast(data));
    c.wl_callback_destroy(callback);
    const frameCallback = c.wl_surface_frame(window.backend.wayland.wlSurface);
    _ = c.wl_callback_add_listener(frameCallback, &frameListener, window);

    Platform.writeEvent(.{ .window_refresh = .{ .window = window.id } });
}

const seatListener = c.wl_seat_listener{
    .capabilities = seatCapabilities,
    .name = seatName,
};

fn seatCapabilities(data: ?*anyopaque, seat: ?*c.wl_seat, capability: u32) callconv(.C) void {
    _ = seat;

    const backend: *Wayland = @alignCast(@ptrCast(data));
    std.log.debug("Seat capability: {d}", .{capability});
    const usePointer = (capability & c.WL_SEAT_CAPABILITY_POINTER) != 0;
    const useKeyboard = (capability & c.WL_SEAT_CAPABILITY_KEYBOARD) != 0;

    if (usePointer and backend.pointer == null) {
        std.log.debug("seat: add pointer", .{});
        backend.pointer = c.wl_seat_get_pointer(backend.seat);
        _ = c.wl_pointer_add_listener(backend.pointer, &pointerListener, backend);
    } else if (!usePointer and backend.pointer != null) {
        std.log.debug("seat: remove pointer", .{});
        c.wl_pointer_release(backend.pointer);
        backend.pointer = null;
    }

    if (useKeyboard and backend.keyboard == null) {
        std.log.debug("seat: add keyboard", .{});
        backend.keyboard = c.wl_seat_get_keyboard(backend.seat);
        _ = c.wl_keyboard_add_listener(backend.keyboard, &keyboardListener, backend);
    } else if (!useKeyboard and backend.keyboard != null) {
        std.log.debug("seat: remove keyboard", .{});
        c.wl_keyboard_release(backend.keyboard);
        backend.keyboard = null;
    }

    backend.seatCapabilities = .{
        .pointer = usePointer,
        .keyboard = useKeyboard,
    };
}

fn seatName(data: ?*anyopaque, seat: ?*c.wl_seat, name: [*c]const u8) callconv(.C) void {
    _ = data;
    _ = seat;

    std.log.debug("Seat name: {s}", .{name});
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
    std.log.debug("wl_pointer.axis: time = {d}, axis = {d}, value = {d}", .{ time, axis, value });
}

fn pointerAxisDiscrete(data: ?*anyopaque, pointer: ?*c.wl_pointer, axis: u32, discrete: i32) callconv(.C) void {
    _ = data;
    _ = pointer;
    std.log.debug("wl_pointer.axis_discrete: axis = {d}, discrete = {d}", .{ axis, discrete });
}

fn pointerAxisRelativeDirection(data: ?*anyopaque, pointer: ?*c.wl_pointer, axis: u32, direction: u32) callconv(.C) void {
    _ = data;
    _ = pointer;
    std.log.debug("wl_pointer.axis_relative_direction: axis = {d}, direction = {d}", .{ axis, direction });
}

fn pointerAxisSource(data: ?*anyopaque, pointer: ?*c.wl_pointer, source: u32) callconv(.C) void {
    _ = data;
    _ = pointer;
    std.log.debug("wl_pointer.axis_source: source = {d}", .{source});
}

fn pointerAxisStop(data: ?*anyopaque, pointer: ?*c.wl_pointer, time: u32, axis: u32) callconv(.C) void {
    _ = data;
    _ = pointer;
    std.log.debug("wl_pointer.axis_stop: time = {d}, axis = {d}", .{ time, axis });
}

fn pointerAxisValue120(data: ?*anyopaque, pointer: ?*c.wl_pointer, axis: u32, value120: i32) callconv(.C) void {
    _ = data;
    _ = pointer;
    std.log.debug("wl_pointer.axis_value120: axis = {d}, value120 = {d}", .{ axis, value120 });
}

fn pointerButton(data: ?*anyopaque, pointer: ?*c.wl_pointer, serial: u32, time: u32, button: u32, state: u32) callconv(.C) void {
    _ = data;
    _ = pointer;
    std.log.debug("wl_pointer.button: serial = {d}, time = {d}, button = {d}, state = {d}", .{ serial, time, button, state });
}

fn pointerEnter(data: ?*anyopaque, pointer: ?*c.wl_pointer, serial: u32, surface: ?*c.wl_surface, x: c.wl_fixed_t, y: c.wl_fixed_t) callconv(.C) void {
    _ = data;
    _ = pointer;
    _ = surface;
    std.log.debug("wl_pointer.enter: serial = {d}, x = {}, y = {}", .{ serial, x, y });
}

fn pointerFrame(data: ?*anyopaque, pointer: ?*c.wl_pointer) callconv(.C) void {
    _ = data;
    _ = pointer;
    std.log.debug("wl_pointer.frame", .{});
}

fn pointerLeave(data: ?*anyopaque, pointer: ?*c.wl_pointer, serial: u32, surface: ?*c.wl_surface) callconv(.C) void {
    _ = data;
    _ = pointer;
    _ = surface;
    std.log.debug("wl_pointer.leave: serial = {d}", .{serial});
}

fn pointerMotion(data: ?*anyopaque, pointer: ?*c.wl_pointer, time: u32, x: c.wl_fixed_t, y: c.wl_fixed_t) callconv(.C) void {
    _ = data;
    _ = pointer;
    std.log.debug("wl_pointer.motion: time = {d}, x = {d}, y = {d}", .{ time, std.math.round(@as(f32, @floatFromInt(x)) / 255), std.math.round(@as(f32, @floatFromInt(y)) / 255) });
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
    std.log.debug("wl_keyboard.enter: serial = {d}, keys = {d}", .{ serial, keysArray.size });
}

fn keyboardKey(data: ?*anyopaque, keyboard: ?*c.wl_keyboard, serial: u32, time: u32, key: u32, state: u32) callconv(.C) void {
    _ = keyboard;
    const backend: *Wayland = @alignCast(@ptrCast(data));
    const keycode = key + 8;
    const sym = c.xkb_state_key_get_one_sym(backend.xkb.state, keycode);
    std.log.debug("wl_keyboard.key: serial = {d}, time = {d}, key = {d}, sym = {d}, state = {d}", .{ serial, time, key, sym, state });
}

fn keyboardKeymap(data: ?*anyopaque, keyboard: ?*c.wl_keyboard, format: u32, fd: i32, size: u32) callconv(.C) void {
    _ = keyboard;
    std.log.debug("wl_keyboard.keymap", .{});
    const backend: *Wayland = @alignCast(@ptrCast(data));
    assert(format == c.WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1);
    c.xkb_keymap_unref(backend.xkb.keymap);
    const shm = std.posix.mmap(null, size, std.posix.PROT.READ, @bitCast(std.posix.MAP{ .TYPE = .PRIVATE }), fd, 0) catch unreachable;
    backend.xkb.keymap = c.xkb_keymap_new_from_string(backend.xkb.context, shm.ptr, c.XKB_KEYMAP_FORMAT_TEXT_V1, c.XKB_KEYMAP_COMPILE_NO_FLAGS);
    std.posix.munmap(shm);
    std.posix.close(fd);
    c.xkb_state_unref(backend.xkb.state);
    backend.xkb.state = c.xkb_state_new(backend.xkb.keymap);
}

fn keyboardLeave(data: ?*anyopaque, keyboard: ?*c.wl_keyboard, serial: u32, surface: ?*c.wl_surface) callconv(.C) void {
    _ = data;
    _ = keyboard;
    _ = surface;
    std.log.debug("wl_keyboard.leave: serial = {d}", .{serial});
}

fn keyboardModifiers(data: ?*anyopaque, keyboard: ?*c.wl_keyboard, serial: u32, depressed: u32, latched: u32, locked: u32, group: u32) callconv(.C) void {
    _ = keyboard;
    _ = serial;
    const backend: *Wayland = @alignCast(@ptrCast(data));
    _ = c.xkb_state_update_mask(backend.xkb.state, depressed, latched, locked, 0, 0, group);
}

fn keyboardRepeatInfo(data: ?*anyopaque, keyboard: ?*c.wl_keyboard, rate: i32, delay: i32) callconv(.C) void {
    _ = data;
    _ = keyboard;
    std.log.debug("wl_keyboard.repeat_info: = rate = {d}, delay = {d}", .{ rate, delay });
}
