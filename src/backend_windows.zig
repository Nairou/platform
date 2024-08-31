const std = @import("std");
const win32 = @import("helper_win32.zig");
const d3d = @import("helper_d3d11.zig");
const dxgi = @import("helper_dxgi.zig");
const Platform = @import("lib.zig");
const BackendError = @import("lib.zig").BackendError;
const Window = @import("lib.zig").Window;
const WindowId = @import("lib.zig").WindowId;
const assert = std.debug.assert;

const PropName = "_platform";

device: *d3d.ID3D11Device = undefined,
context: *d3d.ID3D11DeviceContext = undefined,

pub const WindowData = struct {
    handle: win32.HWND = undefined,
    swapChain: *d3d.IDXGISwapChain = undefined,
    renderTargetView: *d3d.ID3D11RenderTargetView = undefined,
};

const Windows = @This();

pub fn init(self: *Windows, allocator: std.mem.Allocator) !void {
    _ = allocator;
    std.log.warn("init windows", .{});
    const featureLevels = [_]d3d.D3D11_FEATURE_LEVEL{.@"11_0"};
    const deviceResult = d3d.CreateDevice(null, .HARDWARE, null, .{}, @ptrCast(&featureLevels), featureLevels.len, d3d.D3D11_SDK_VERSION, &self.device, null, &self.context);
    if (deviceResult != 0) {
        std.log.err("D3D11CreateDevice error code: 0x{x}", .{deviceResult});
        return error.CantCreateDevice;
    }
    std.log.debug("self.device = {any}", .{self.device});
}

pub fn deinit(self: *Windows) void {
    std.log.debug("self.device = {any}", .{self.device});
    _ = self.device.Release();
    _ = self.context.Release();
}

pub fn processEvents(backend: *Windows, wait: bool) void {
    _ = wait;
    _ = backend;
    var msg: win32.MSG = undefined;
    while (win32.PeekMessage(&msg, null, 0, 0, win32.PM_REMOVE) != 0) {
        if (msg.message == win32.WM_QUIT) {
            Platform.writeEvent(.{ .exit = {} });
            return;
        }
        _ = win32.TranslateMessage(&msg);
        _ = win32.DispatchMessage(&msg);
    }
}

pub fn getProcAddress(self: *Windows, proc: [:0]const u8) ?*const anyopaque {
    _ = self;
    _ = proc;
    return null;
}

pub fn initWindow(self: *Windows, window: *Window) !void {
    std.log.debug("Window: {any}", .{window});

    window.backend = .{ .windows = WindowData{} };
    const instance = win32.GetModuleHandle(null);
    var wndClass = std.mem.zeroInit(win32.WNDCLASSEX, .{
        .cbSize = @sizeOf(win32.WNDCLASSEX),
        .lpfnWndProc = windowProc,
        .hInstance = @as(win32.HINSTANCE, @ptrCast(instance)),
        //.hCursor = win32.LoadCursorA(null, win32.IDC_ARROW),
        .lpszClassName = "platform",
    });
    const class = win32.RegisterClassEx(&wndClass);
    if (class == 0) {
        std.log.err("Error registering window class ({d})", .{win32.GetLastError()});
        return error.RegisterClass;
    }

    const handle = win32.CreateWindowEx(0, @ptrFromInt(class), "Test Window", win32.WS_OVERLAPPEDWINDOW, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, null, null, @ptrCast(instance), null);
    if (handle) |hwnd| {
        window.backend.windows.handle = @ptrCast(hwnd);
    } else {
        std.log.err("Error creating window ({d})", .{win32.GetLastError()});
        return error.CreateWindow;
    }

    _ = win32.SetProp(window.backend.windows.handle, PropName, window);

    var factory: *d3d.IDXGIFactory1 = undefined;
    const factoryResult = d3d.CreateDXGIFactory1(&d3d.IDXGIFactory1.IID, &factory);
    if (factoryResult != 0) {
        std.log.err("CreateDXGIFactory1 error code: 0x{x}", .{factoryResult});
        return error.CantCreateSwapChain;
    }
    defer _ = factory.Release();
    var swapChainDesc = std.mem.zeroInit(dxgi.DXGI_SWAP_CHAIN_DESC, .{
        .BufferCount = 1,
        .BufferDesc = .{ .Format = .R8G8B8A8_UNORM },
        .BufferUsage = .{ .RENDER_TARGET_OUTPUT = true },
        .OutputWindow = window.backend.windows.handle,
        .SampleDesc = .{ .Count = 1 },
        .Windowed = 1,
    });
    const swapChainResult = factory.CreateSwapChain(@ptrCast(self.device), &swapChainDesc, &window.backend.windows.swapChain);
    if (swapChainResult != 0) {
        std.log.err("CreateSwapChain error code: 0x{x}", .{swapChainResult});
        return error.CantCreateSwapChain;
    }

    var backBuffer: *d3d.ID3D11Texture2D = undefined;
    const bufferResult = window.backend.windows.swapChain.GetBuffer(0, &d3d.ID3D11Texture2D.IID, @ptrCast(&backBuffer));
    if (bufferResult != 0) {
        std.log.err("GetBuffer error code: 0x{x}", .{bufferResult});
        return error.CantCreateBackBuffer;
    }
    defer _ = backBuffer.Release();

    const renderTargetResult = self.device.CreateRenderTargetView(@ptrCast(backBuffer), null, &window.backend.windows.renderTargetView);
    if (renderTargetResult < 0) {
        std.log.err("RenderTargetView error code: 0x{x}", .{renderTargetResult});
        return error.CantCreateRenderTargetView;
    }

    _ = self.context.OMSetRenderTargets(1, &window.backend.windows.renderTargetView, null);

    var viewport = std.mem.zeroInit(d3d.D3D11_VIEWPORT, .{
        .Width = 1024,
        .Height = 768,
        .TopLeftX = 0,
        .TopLeftY = 0,
        .MinDepth = 0,
        .MaxDepth = 1,
    });
    self.context.RSSetViewports(1, @ptrCast(&viewport));

    _ = win32.ShowWindow(window.backend.windows.handle, win32.SW_HIDE);
    _ = win32.ShowWindow(window.backend.windows.handle, win32.SW_SHOW);
}

pub fn deinitWindow(window: *Window) void {
    _ = window;
}

pub fn swapWindowBuffer(self: *Windows, window: *Window) void {
    const color = [_]f32{ 1, 0, 0, 1 };
    self.context.ClearRenderTargetView(window.backend.windows.renderTargetView, &color);
    _ = window.backend.windows.swapChain.Present(1, 0);
}

fn windowProc(hwnd: ?win32.HWND, uMsg: win32.UINT, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(win32.WINAPI) win32.LRESULT {
    const windowRef = @as(?*Window, @alignCast(@ptrCast(win32.GetProp(hwnd, PropName))));
    if (windowRef) |window| {
        //std.log.debug("windowProc, window = {d}, uMsg = {d}", .{ window.id, uMsg });
        switch (uMsg) {
            win32.WM_CLOSE => {
                Platform.writeEvent(.{ .window_close = .{ .window = window.id } });
                return 0;
            },
            win32.WM_PAINT => {
                Platform.writeEvent(.{ .window_refresh = .{ .window = window.id } });
            },
            win32.WM_SIZE => {
                window.width = @intCast((lParam) & 0xffff);
                window.height = @intCast((lParam >> 16) & 0xffff);
                Platform.writeEvent(.{ .window_size = .{ .window = window.id, .width = window.width, .height = window.height } });
            },
            else => {},
        }
    } else {
        std.log.debug("windowProc, uMsg = {d}", .{uMsg});
        switch (uMsg) {
            else => {},
        }
    }
    return win32.DefWindowProc(hwnd, uMsg, wParam, lParam);
}
