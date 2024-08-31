const std = @import("std");
const win32 = @import("helper_win32.zig");
const HANDLE = std.os.windows.HANDLE;
const HMONITOR = std.os.windows.HANDLE;
const HWND = std.os.windows.HWND;
const LARGE_INTEGER = i64;
const LUID = win32.LUID;
const RECT = win32.RECT;
const SIZE_T = usize;
const WINBOOL = std.os.windows.BOOL;

// Constants
pub const DXGI_ADAPTER_DESC = extern struct {
    Description: [128]u16,
    VendorId: u32,
    DeviceId: u32,
    SubSysId: u32,
    Revision: u32,
    DedicatedVideoMemory: SIZE_T,
    DedicatedSystemMemory: SIZE_T,
    SharedSystemMemory: SIZE_T,
    AdapterLuid: LUID,
};
pub const DXGI_ADAPTER_DESC1 = extern struct {
    Description: [128]u16,
    VendorId: u32,
    DeviceId: u32,
    SubSysId: u32,
    Revision: u32,
    DedicatedVideoMemory: SIZE_T,
    DedicatedSystemMemory: SIZE_T,
    SharedSystemMemory: SIZE_T,
    AdapterLuid: LUID,
    Flags: u32,
};
pub const DXGI_ADAPTER_FLAG = enum(u32) {
    DXGI_ADAPTER_FLAG_NONE = 0,
    DXGI_ADAPTER_FLAG_REMOTE = 1,
    DXGI_ADAPTER_FLAG_SOFTWARE = 2,
    DXGI_ADAPTER_FLAG_FORCE_DWORD = 0xffffffff,
};
pub const DXGI_CENTER_MULTISAMPLE_QUALITY_PATTERN = 0xfffffffe;
pub const DXGI_COLOR_SPACE_TYPE = enum(u32) {
    DXGI_COLOR_SPACE_RGB_FULL_G22_NONE_P709 = 0x0,
    DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709 = 0x1,
    DXGI_COLOR_SPACE_RGB_STUDIO_G22_NONE_P709 = 0x2,
    DXGI_COLOR_SPACE_RGB_STUDIO_G22_NONE_P2020 = 0x3,
    DXGI_COLOR_SPACE_RESERVED = 0x4,
    DXGI_COLOR_SPACE_YCBCR_FULL_G22_NONE_P709_X601 = 0x5,
    DXGI_COLOR_SPACE_YCBCR_STUDIO_G22_LEFT_P601 = 0x6,
    DXGI_COLOR_SPACE_YCBCR_FULL_G22_LEFT_P601 = 0x7,
    DXGI_COLOR_SPACE_YCBCR_STUDIO_G22_LEFT_P709 = 0x8,
    DXGI_COLOR_SPACE_YCBCR_FULL_G22_LEFT_P709 = 0x9,
    DXGI_COLOR_SPACE_YCBCR_STUDIO_G22_LEFT_P2020 = 0xa,
    DXGI_COLOR_SPACE_YCBCR_FULL_G22_LEFT_P2020 = 0xb,
    DXGI_COLOR_SPACE_RGB_FULL_G2084_NONE_P2020 = 0xc,
    DXGI_COLOR_SPACE_YCBCR_STUDIO_G2084_LEFT_P2020 = 0xd,
    DXGI_COLOR_SPACE_RGB_STUDIO_G2084_NONE_P2020 = 0xe,
    DXGI_COLOR_SPACE_YCBCR_STUDIO_G22_TOPLEFT_P2020 = 0xf,
    DXGI_COLOR_SPACE_YCBCR_STUDIO_G2084_TOPLEFT_P2020 = 0x10,
    DXGI_COLOR_SPACE_RGB_FULL_G22_NONE_P2020 = 0x11,
    DXGI_COLOR_SPACE_YCBCR_STUDIO_GHLG_TOPLEFT_P2020 = 0x12,
    DXGI_COLOR_SPACE_YCBCR_FULL_GHLG_TOPLEFT_P2020 = 0x13,
    DXGI_COLOR_SPACE_RGB_STUDIO_G24_NONE_P709 = 0x14,
    DXGI_COLOR_SPACE_RGB_STUDIO_G24_NONE_P2020 = 0x15,
    DXGI_COLOR_SPACE_YCBCR_STUDIO_G24_LEFT_P709 = 0x16,
    DXGI_COLOR_SPACE_YCBCR_STUDIO_G24_LEFT_P2020 = 0x17,
    DXGI_COLOR_SPACE_YCBCR_STUDIO_G24_TOPLEFT_P2020 = 0x18,
    DXGI_COLOR_SPACE_CUSTOM = 0xffffffff,
};
pub const DXGI_CPU_ACCESS_DYNAMIC = 1;
pub const DXGI_CPU_ACCESS_FIELD = 15;
pub const DXGI_CPU_ACCESS_NONE = 0;
pub const DXGI_CPU_ACCESS_READ_WRITE = 2;
pub const DXGI_CPU_ACCESS_SCRATCH = 3;
pub const DXGI_DISPLAY_COLOR_SPACE = extern struct {
    PrimaryCoordinates: [8]f32[2],
    WhitePoints: [16]f32[2],
};
pub const DXGI_ENUM_MODES_INTERLACED = 1;
pub const DXGI_ENUM_MODES_SCALING = 2;
pub const DXGI_FORMAT = enum(u32) {
    UNKNOWN = 0x0,
    R32G32B32A32_TYPELESS = 0x1,
    R32G32B32A32_FLOAT = 0x2,
    R32G32B32A32_u32 = 0x3,
    R32G32B32A32_SINT = 0x4,
    R32G32B32_TYPELESS = 0x5,
    R32G32B32_FLOAT = 0x6,
    R32G32B32_u32 = 0x7,
    R32G32B32_SINT = 0x8,
    R16G16B16A16_TYPELESS = 0x9,
    R16G16B16A16_FLOAT = 0xa,
    R16G16B16A16_UNORM = 0xb,
    R16G16B16A16_u32 = 0xc,
    R16G16B16A16_SNORM = 0xd,
    R16G16B16A16_SINT = 0xe,
    R32G32_TYPELESS = 0xf,
    R32G32_FLOAT = 0x10,
    R32G32_u32 = 0x11,
    R32G32_SINT = 0x12,
    R32G8X24_TYPELESS = 0x13,
    D32_FLOAT_S8X24_u32 = 0x14,
    R32_FLOAT_X8X24_TYPELESS = 0x15,
    X32_TYPELESS_G8X24_u32 = 0x16,
    R10G10B10A2_TYPELESS = 0x17,
    R10G10B10A2_UNORM = 0x18,
    R10G10B10A2_u32 = 0x19,
    R11G11B10_FLOAT = 0x1a,
    R8G8B8A8_TYPELESS = 0x1b,
    R8G8B8A8_UNORM = 0x1c,
    R8G8B8A8_UNORM_SRGB = 0x1d,
    R8G8B8A8_u32 = 0x1e,
    R8G8B8A8_SNORM = 0x1f,
    R8G8B8A8_SINT = 0x20,
    R16G16_TYPELESS = 0x21,
    R16G16_FLOAT = 0x22,
    R16G16_UNORM = 0x23,
    R16G16_u32 = 0x24,
    R16G16_SNORM = 0x25,
    R16G16_SINT = 0x26,
    R32_TYPELESS = 0x27,
    D32_FLOAT = 0x28,
    R32_FLOAT = 0x29,
    R32_u32 = 0x2a,
    R32_SINT = 0x2b,
    R24G8_TYPELESS = 0x2c,
    D24_UNORM_S8_u32 = 0x2d,
    R24_UNORM_X8_TYPELESS = 0x2e,
    X24_TYPELESS_G8_u32 = 0x2f,
    R8G8_TYPELESS = 0x30,
    R8G8_UNORM = 0x31,
    R8G8_u32 = 0x32,
    R8G8_SNORM = 0x33,
    R8G8_SINT = 0x34,
    R16_TYPELESS = 0x35,
    R16_FLOAT = 0x36,
    D16_UNORM = 0x37,
    R16_UNORM = 0x38,
    R16_u32 = 0x39,
    R16_SNORM = 0x3a,
    R16_SINT = 0x3b,
    R8_TYPELESS = 0x3c,
    R8_UNORM = 0x3d,
    R8_u32 = 0x3e,
    R8_SNORM = 0x3f,
    R8_SINT = 0x40,
    A8_UNORM = 0x41,
    R1_UNORM = 0x42,
    R9G9B9E5_SHAREDEXP = 0x43,
    R8G8_B8G8_UNORM = 0x44,
    G8R8_G8B8_UNORM = 0x45,
    BC1_TYPELESS = 0x46,
    BC1_UNORM = 0x47,
    BC1_UNORM_SRGB = 0x48,
    BC2_TYPELESS = 0x49,
    BC2_UNORM = 0x4a,
    BC2_UNORM_SRGB = 0x4b,
    BC3_TYPELESS = 0x4c,
    BC3_UNORM = 0x4d,
    BC3_UNORM_SRGB = 0x4e,
    BC4_TYPELESS = 0x4f,
    BC4_UNORM = 0x50,
    BC4_SNORM = 0x51,
    BC5_TYPELESS = 0x52,
    BC5_UNORM = 0x53,
    BC5_SNORM = 0x54,
    B5G6R5_UNORM = 0x55,
    B5G5R5A1_UNORM = 0x56,
    B8G8R8A8_UNORM = 0x57,
    B8G8R8X8_UNORM = 0x58,
    R10G10B10_XR_BIAS_A2_UNORM = 0x59,
    B8G8R8A8_TYPELESS = 0x5a,
    B8G8R8A8_UNORM_SRGB = 0x5b,
    B8G8R8X8_TYPELESS = 0x5c,
    B8G8R8X8_UNORM_SRGB = 0x5d,
    BC6H_TYPELESS = 0x5e,
    BC6H_UF16 = 0x5f,
    BC6H_SF16 = 0x60,
    BC7_TYPELESS = 0x61,
    BC7_UNORM = 0x62,
    BC7_UNORM_SRGB = 0x63,
    AYUV = 0x64,
    Y410 = 0x65,
    Y416 = 0x66,
    NV12 = 0x67,
    P010 = 0x68,
    P016 = 0x69,
    @"420_OPAQUE" = 0x6a,
    YUY2 = 0x6b,
    Y210 = 0x6c,
    Y216 = 0x6d,
    NV11 = 0x6e,
    AI44 = 0x6f,
    IA44 = 0x70,
    P8 = 0x71,
    A8P8 = 0x72,
    B4G4R4A4_UNORM = 0x73,
    P208 = 0x82,
    V208 = 0x83,
    V408 = 0x84,
    FORCE_u32 = 0xffffffff,
};
pub const DXGI_FRAME_STATISTICS = extern struct {
    PresentCount: u32,
    PresentRefreshCount: u32,
    SyncRefreshCount: u32,
    SyncQPCTime: LARGE_INTEGER,
    SyncGPUTime: LARGE_INTEGER,
};
pub const DXGI_GAMMA_CONTROL = extern struct {
    Scale: DXGI_RGB,
    Offset: DXGI_RGB,
    GammaCurve: [1025]DXGI_RGB,
};
pub const DXGI_GAMMA_CONTROL_CAPABILITIES = extern struct {
    ScaleAndOffsetSupported: WINBOOL,
    MaxConvertedValue: f32,
    MinConvertedValue: f32,
    NumGammaControlPoints: u32,
    ControlPointPositions: [1025]f32,
};
pub const DXGI_MAP_DISCARD = 0x4;
pub const DXGI_MAP_READ = 0x1;
pub const DXGI_MAP_WRITE = 0x2;
pub const DXGI_MAPPED_RECT = extern struct {
    Pitch: i32,
    pBits: *u8,
};
pub const DXGI_MAX_SWAP_CHAIN_BUFFERS = 16;
pub const DXGI_MODE_DESC = extern struct {
    Width: u32,
    Height: u32,
    RefreshRate: DXGI_RATIONAL,
    Format: DXGI_FORMAT,
    ScanlineOrdering: DXGI_MODE_SCANLINE_ORDER,
    Scaling: DXGI_MODE_SCALING,
};
pub const DXGI_MODE_ROTATION = enum(u32) {
    UNSPECIFIED = 0x0,
    IDENTITY = 0x1,
    ROTATE90 = 0x2,
    ROTATE180 = 0x3,
    ROTATE270 = 0x4,
};
pub const DXGI_MODE_SCALING = enum(u32) {
    UNSPECIFIED = 0x0,
    CENTERED = 0x1,
    STRETCHED = 0x2,
};
pub const DXGI_MODE_SCANLINE_ORDER = enum(u32) {
    UNSPECIFIED = 0x0,
    PROGRESSIVE = 0x1,
    UPPER_FIELD_FIRST = 0x2,
    LOWER_FIELD_FIRST = 0x3,
};
pub const DXGI_MWA_NO_ALT_ENTER = 0x2;
pub const DXGI_MWA_NO_PRINT_SCREEN = 0x4;
pub const DXGI_MWA_NO_WINDOW_CHANGES = 0x1;
pub const DXGI_MWA_VALID = 0x7;
pub const DXGI_OUTPUT_DESC = extern struct {
    DeviceName: [32]u16,
    DesktopCoordinates: RECT,
    AttachedToDesktop: WINBOOL,
    Rotation: DXGI_MODE_ROTATION,
    Monitor: HMONITOR,
};
pub const DXGI_PRESENT_ALLOW_TEARING = 0x00000200;
pub const DXGI_PRESENT_DO_NOT_SEQUENCE = 0x00000002;
pub const DXGI_PRESENT_DO_NOT_WAIT = 0x00000008;
pub const DXGI_PRESENT_RESTART = 0x00000004;
pub const DXGI_PRESENT_RESTRICT_TO_OUTPUT = 0x00000040;
pub const DXGI_PRESENT_STEREO_PREFER_RIGHT = 0x00000010;
pub const DXGI_PRESENT_STEREO_TEMPORARY_MONO = 0x00000020;
pub const DXGI_PRESENT_TEST = 0x00000001;
pub const DXGI_PRESENT_USE_DURATION = 0x00000100;
pub const DXGI_RATIONAL = extern struct {
    Numerator: u32,
    Denominator: u32,
};
pub const DXGI_RESIDENCY = enum(u32) {
    DXGI_RESIDENCY_FULLY_RESIDENT = 1,
    DXGI_RESIDENCY_RESIDENT_IN_SHARED_MEMORY = 2,
    DXGI_RESIDENCY_EVICTED_TO_DISK = 3,
};
pub const DXGI_RESOURCE_PRIORITY_HIGH = 0xa0000000;
pub const DXGI_RESOURCE_PRIORITY_LOW = 0x50000000;
pub const DXGI_RESOURCE_PRIORITY_MAXIMUM = 0xc8000000;
pub const DXGI_RESOURCE_PRIORITY_MINIMUM = 0x28000000;
pub const DXGI_RESOURCE_PRIORITY_NORMAL = 0x78000000;
pub const DXGI_RGB = extern struct {
    Red: f32,
    Green: f32,
    Blue: f32,
};
pub const DXGI_SAMPLE_DESC = extern struct {
    Count: u32,
    Quality: u32,
};
pub const DXGI_SHARED_RESOURCE = extern struct {
    Handle: HANDLE,
};
pub const DXGI_STANDARD_MULTISAMPLE_QUALITY_PATTERN = 0xffffffff;
pub const DXGI_SURFACE_DESC = extern struct {
    Width: u32,
    Height: u32,
    Format: DXGI_FORMAT,
    SampleDesc: DXGI_SAMPLE_DESC,
};
pub const DXGI_SWAP_CHAIN_DESC = extern struct {
    BufferDesc: DXGI_MODE_DESC,
    SampleDesc: DXGI_SAMPLE_DESC,
    BufferUsage: DXGI_USAGE,
    BufferCount: u32,
    OutputWindow: HWND,
    Windowed: WINBOOL,
    SwapEffect: DXGI_SWAP_EFFECT,
    Flags: u32,
};
pub const DXGI_SWAP_CHAIN_FLAG = enum(u32) {
    DXGI_SWAP_CHAIN_FLAG_NONPREROTATED = 0x1,
    DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH = 0x2,
    DXGI_SWAP_CHAIN_FLAG_GDI_COMPATIBLE = 0x4,
    DXGI_SWAP_CHAIN_FLAG_RESTRICTED_CONTENT = 0x8,
    DXGI_SWAP_CHAIN_FLAG_RESTRICT_SHARED_RESOURCE_DRIVER = 0x10,
    DXGI_SWAP_CHAIN_FLAG_DISPLAY_ONLY = 0x20,
    DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT = 0x40,
    DXGI_SWAP_CHAIN_FLAG_FOREGROUND_LAYER = 0x80,
    DXGI_SWAP_CHAIN_FLAG_FULLSCREEN_VIDEO = 0x100,
    DXGI_SWAP_CHAIN_FLAG_YUV_VIDEO = 0x200,
    DXGI_SWAP_CHAIN_FLAG_HW_PROTECTED = 0x400,
    DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING = 0x800,
    DXGI_SWAP_CHAIN_FLAG_RESTRICTED_TO_ALL_HOLOGRAPHIC_DISPLAYS = 0x1000,
};
pub const DXGI_SWAP_EFFECT = enum(u32) {
    DXGI_SWAP_EFFECT_DISCARD = 0,
    DXGI_SWAP_EFFECT_SEQUENTIAL = 1,
    DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL = 3,
    DXGI_SWAP_EFFECT_FLIP_DISCARD = 4,
};
pub const DXGI_USAGE = packed struct(u32) {
    unused1: u4 = 0,
    SHADER_INPUT: bool = false,
    RENDER_TARGET_OUTPUT: bool = false,
    BACK_BUFFER: bool = false,
    SHARED: bool = false,
    READ_ONLY: bool = false,
    DISCARD_ON_PRESENT: bool = false,
    UNORDERED_ACCESS: bool = false,
    unused2: u21 = 0,
};
