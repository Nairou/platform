const std = @import("std");

// Types
pub const ATOM = std.os.windows.ATOM;
pub const DWORD = std.os.windows.DWORD;
pub const GUID = std.os.windows.GUID;
pub const HANDLE = std.os.windows.HANDLE;
pub const HBRUSH = std.os.windows.HBRUSH;
pub const HCURSOR = std.os.windows.HCURSOR;
pub const HICON = std.os.windows.HICON;
pub const HINSTANCE = std.os.windows.HINSTANCE;
pub const HMENU = std.os.windows.HMENU;
pub const HMODULE = std.os.windows.HMODULE;
pub const HRESULT = std.os.windows.HRESULT;
pub const HWND = std.os.windows.HWND;
pub const UINT = std.os.windows.UINT;
pub const LPARAM = std.os.windows.LPARAM;
pub const LPCSTR = std.os.windows.LPCSTR;
pub const LPSTR = std.os.windows.LPSTR;
pub const LONG = std.os.windows.LONG;
pub const LRESULT = std.os.windows.LRESULT;
pub const POINT = std.os.windows.POINT;
pub const ULONG = std.os.windows.ULONG;
pub const WINAPI = std.os.windows.WINAPI;
pub const WINBOOL = std.os.windows.BOOL;
pub const WPARAM = std.os.windows.WPARAM;

// Constants
pub const CW_USEDEFAULT = @as(i32, @bitCast(@as(u32, 0x80000000)));

pub const LANG_ENGLISH = 0x09;

pub const PM_NOREMOVE = 0x0000;
pub const PM_REMOVE = 0x0001;
pub const PM_NOYIELD = 0x0002;

pub const SW_HIDE = 0;
pub const SW_SHOWNORMAL = 1;
pub const SW_NORMAL = 1;
pub const SW_SHOWMINIMIZED = 2;
pub const SW_SHOWMAXIMIZED = 3;
pub const SW_MAXIMIZE = 3;
pub const SW_SHOWNOACTIVATE = 4;
pub const SW_SHOW = 5;
pub const SW_MINIMIZE = 6;
pub const SW_SHOWMINNOACTIVE = 7;
pub const SW_SHOWNA = 8;
pub const SW_RESTORE = 9;
pub const SW_SHOWDEFAULT = 10;
pub const SW_FORCEMINIMIZE = 11;
pub const SW_MAX = 11;

pub const WM_NULL = 0x0000;
pub const WM_CREATE = 0x0001;
pub const WM_DESTROY = 0x0002;
pub const WM_MOVE = 0x0003;
pub const WM_SIZE = 0x0005;
pub const WM_ACTIVATE = 0x0006;
pub const WA_INACTIVE = 0;
pub const WA_ACTIVE = 1;
pub const WA_CLICKACTIVE = 2;
pub const WM_SETFOCUS = 0x0007;
pub const WM_KILLFOCUS = 0x0008;
pub const WM_ENABLE = 0x000A;
pub const WM_SETREDRAW = 0x000B;
pub const WM_SETTEXT = 0x000C;
pub const WM_GETTEXT = 0x000D;
pub const WM_GETTEXTLENGTH = 0x000E;
pub const WM_PAINT = 0x000F;
pub const WM_CLOSE = 0x0010;
pub const WM_QUERYENDSESSION = 0x0011;
pub const WM_QUERYOPEN = 0x0013;
pub const WM_ENDSESSION = 0x0016;
pub const WM_QUIT = 0x0012;
pub const WM_ERASEBKGND = 0x0014;
pub const WM_SYSCOLORCHANGE = 0x0015;
pub const WM_SHOWWINDOW = 0x0018;
pub const WM_WININICHANGE = 0x001A;
pub const WM_SETTINGCHANGE = WM_WININICHANGE;
pub const WM_DEVMODECHANGE = 0x001B;
pub const WM_ACTIVATEAPP = 0x001C;
pub const WM_FONTCHANGE = 0x001D;
pub const WM_TIMECHANGE = 0x001E;
pub const WM_CANCELMODE = 0x001F;
pub const WM_SETCURSOR = 0x0020;
pub const WM_MOUSEACTIVATE = 0x0021;
pub const WM_CHILDACTIVATE = 0x0022;
pub const WM_QUEUESYNC = 0x0023;
pub const WM_GETMINMAXINFO = 0x0024;
pub const WM_PAINTICON = 0x0026;
pub const WM_ICONERASEBKGND = 0x0027;
pub const WM_NEXTDLGCTL = 0x0028;
pub const WM_SPOOLERSTATUS = 0x002A;
pub const WM_DRAWITEM = 0x002B;
pub const WM_MEASUREITEM = 0x002C;
pub const WM_DELETEITEM = 0x002D;
pub const WM_VKEYTOITEM = 0x002E;
pub const WM_CHARTOITEM = 0x002F;
pub const WM_SETFONT = 0x0030;
pub const WM_GETFONT = 0x0031;
pub const WM_SETHOTKEY = 0x0032;
pub const WM_GETHOTKEY = 0x0033;
pub const WM_QUERYDRAGICON = 0x0037;
pub const WM_COMPAREITEM = 0x0039;
pub const WM_GETOBJECT = 0x003D;
pub const WM_COMPACTING = 0x0041;
pub const WM_COMMNOTIFY = 0x0044;
pub const WM_WINDOWPOSCHANGING = 0x0046;
pub const WM_WINDOWPOSCHANGED = 0x0047;
pub const WM_POWER = 0x0048;
pub const WM_COPYDATA = 0x004A;
pub const WM_CANCELJOURNAL = 0x004B;
pub const WM_NOTIFY = 0x004E;
pub const WM_INPUTLANGCHANGEREQUEST = 0x0050;
pub const WM_INPUTLANGCHANGE = 0x0051;
pub const WM_TCARD = 0x0052;
pub const WM_HELP = 0x0053;
pub const WM_USERCHANGED = 0x0054;
pub const WM_NOTIFYFORMAT = 0x0055;
pub const WM_CONTEXTMENU = 0x007B;
pub const WM_STYLECHANGING = 0x007C;
pub const WM_STYLECHANGED = 0x007D;
pub const WM_DISPLAYCHANGE = 0x007E;
pub const WM_GETICON = 0x007F;
pub const WM_SETICON = 0x0080;
pub const WM_NCCREATE = 0x0081;
pub const WM_NCDESTROY = 0x0082;
pub const WM_NCCALCSIZE = 0x0083;
pub const WM_NCHITTEST = 0x0084;
pub const WM_NCPAINT = 0x0085;
pub const WM_NCACTIVATE = 0x0086;
pub const WM_GETDLGCODE = 0x0087;
pub const WM_SYNCPAINT = 0x0088;
pub const WM_NCMOUSEMOVE = 0x00A0;
pub const WM_NCLBUTTONDOWN = 0x00A1;
pub const WM_NCLBUTTONUP = 0x00A2;
pub const WM_NCLBUTTONDBLCLK = 0x00A3;
pub const WM_NCRBUTTONDOWN = 0x00A4;
pub const WM_NCRBUTTONUP = 0x00A5;
pub const WM_NCRBUTTONDBLCLK = 0x00A6;
pub const WM_NCMBUTTONDOWN = 0x00A7;
pub const WM_NCMBUTTONUP = 0x00A8;
pub const WM_NCMBUTTONDBLCLK = 0x00A9;
pub const WM_NCXBUTTONDOWN = 0x00AB;
pub const WM_NCXBUTTONUP = 0x00AC;
pub const WM_NCXBUTTONDBLCLK = 0x00AD;
pub const WM_INPUT_DEVICE_CHANGE = 0x00fe;
pub const WM_INPUT = 0x00FF;
pub const WM_KEYFIRST = 0x0100;
pub const WM_KEYDOWN = 0x0100;
pub const WM_KEYUP = 0x0101;
pub const WM_CHAR = 0x0102;
pub const WM_DEADCHAR = 0x0103;
pub const WM_SYSKEYDOWN = 0x0104;
pub const WM_SYSKEYUP = 0x0105;
pub const WM_SYSCHAR = 0x0106;
pub const WM_SYSDEADCHAR = 0x0107;
pub const WM_UNICHAR = 0x0109;
pub const WM_KEYLAST = 0x0109;
pub const UNICODE_NOCHAR = 0xFFFF;
pub const WM_IME_STARTCOMPOSITION = 0x010D;
pub const WM_IME_ENDCOMPOSITION = 0x010E;
pub const WM_IME_COMPOSITION = 0x010F;
pub const WM_IME_KEYLAST = 0x010F;
pub const WM_INITDIALOG = 0x0110;
pub const WM_COMMAND = 0x0111;
pub const WM_SYSCOMMAND = 0x0112;
pub const WM_TIMER = 0x0113;
pub const WM_HSCROLL = 0x0114;
pub const WM_VSCROLL = 0x0115;
pub const WM_INITMENU = 0x0116;
pub const WM_INITMENUPOPUP = 0x0117;
pub const WM_MENUSELECT = 0x011F;
pub const WM_GESTURE = 0x0119;
pub const WM_GESTURENOTIFY = 0x011A;
pub const WM_MENUCHAR = 0x0120;
pub const WM_ENTERIDLE = 0x0121;
pub const WM_MENURBUTTONUP = 0x0122;
pub const WM_MENUDRAG = 0x0123;
pub const WM_MENUGETOBJECT = 0x0124;
pub const WM_UNINITMENUPOPUP = 0x0125;
pub const WM_MENUCOMMAND = 0x0126;
pub const WM_CHANGEUISTATE = 0x0127;
pub const WM_UPDATEUISTATE = 0x0128;
pub const WM_QUERYUISTATE = 0x0129;
pub const WM_CTLCOLORMSGBOX = 0x0132;
pub const WM_CTLCOLOREDIT = 0x0133;
pub const WM_CTLCOLORLISTBOX = 0x0134;
pub const WM_CTLCOLORBTN = 0x0135;
pub const WM_CTLCOLORDLG = 0x0136;
pub const WM_CTLCOLORSCROLLBAR = 0x0137;
pub const WM_CTLCOLORSTATIC = 0x0138;
pub const MN_GETHMENU = 0x01E1;
pub const WM_MOUSEFIRST = 0x0200;
pub const WM_MOUSEMOVE = 0x0200;
pub const WM_LBUTTONDOWN = 0x0201;
pub const WM_LBUTTONUP = 0x0202;
pub const WM_LBUTTONDBLCLK = 0x0203;
pub const WM_RBUTTONDOWN = 0x0204;
pub const WM_RBUTTONUP = 0x0205;
pub const WM_RBUTTONDBLCLK = 0x0206;
pub const WM_MBUTTONDOWN = 0x0207;
pub const WM_MBUTTONUP = 0x0208;
pub const WM_MBUTTONDBLCLK = 0x0209;
pub const WM_MOUSEWHEEL = 0x020A;
pub const WM_XBUTTONDOWN = 0x020B;
pub const WM_XBUTTONUP = 0x020C;
pub const WM_XBUTTONDBLCLK = 0x020D;
pub const WM_MOUSEHWHEEL = 0x020e;
pub const WM_MOUSELAST = 0x020e;
pub const WM_PARENTNOTIFY = 0x0210;
pub const WM_ENTERMENULOOP = 0x0211;
pub const WM_EXITMENULOOP = 0x0212;
pub const WM_NEXTMENU = 0x0213;
pub const WM_SIZING = 0x0214;
pub const WM_CAPTURECHANGED = 0x0215;
pub const WM_MOVING = 0x0216;
pub const WM_POWERBROADCAST = 0x0218;
pub const WM_DEVICECHANGE = 0x0219;
pub const WM_MDICREATE = 0x0220;
pub const WM_MDIDESTROY = 0x0221;
pub const WM_MDIACTIVATE = 0x0222;
pub const WM_MDIRESTORE = 0x0223;
pub const WM_MDINEXT = 0x0224;
pub const WM_MDIMAXIMIZE = 0x0225;
pub const WM_MDITILE = 0x0226;
pub const WM_MDICASCADE = 0x0227;
pub const WM_MDIICONARRANGE = 0x0228;
pub const WM_MDIGETACTIVE = 0x0229;
pub const WM_MDISETMENU = 0x0230;
pub const WM_ENTERSIZEMOVE = 0x0231;
pub const WM_EXITSIZEMOVE = 0x0232;
pub const WM_DROPFILES = 0x0233;
pub const WM_MDIREFRESHMENU = 0x0234;
pub const WM_POINTERDEVICECHANGE = 0x238;
pub const WM_POINTERDEVICEINRANGE = 0x239;
pub const WM_POINTERDEVICEOUTOFRANGE = 0x23a;
pub const WM_TOUCH = 0x0240;
pub const WM_NCPOINTERUPDATE = 0x0241;
pub const WM_NCPOINTERDOWN = 0x0242;
pub const WM_NCPOINTERUP = 0x0243;
pub const WM_POINTERUPDATE = 0x0245;
pub const WM_POINTERDOWN = 0x0246;
pub const WM_POINTERUP = 0x0247;
pub const WM_POINTERENTER = 0x0249;
pub const WM_POINTERLEAVE = 0x024a;
pub const WM_POINTERACTIVATE = 0x024b;
pub const WM_POINTERCAPTURECHANGED = 0x024c;
pub const WM_TOUCHHITTESTING = 0x024d;
pub const WM_POINTERWHEEL = 0x024e;
pub const WM_POINTERHWHEEL = 0x024f;
pub const WM_POINTERROUTEDTO = 0x0251;
pub const WM_POINTERROUTEDAWAY = 0x0252;
pub const WM_POINTERROUTEDRELEASED = 0x0253;
pub const WM_IME_SETCONTEXT = 0x0281;
pub const WM_IME_NOTIFY = 0x0282;
pub const WM_IME_CONTROL = 0x0283;
pub const WM_IME_COMPOSITIONFULL = 0x0284;
pub const WM_IME_SELECT = 0x0285;
pub const WM_IME_CHAR = 0x0286;
pub const WM_IME_REQUEST = 0x0288;
pub const WM_IME_KEYDOWN = 0x0290;
pub const WM_IME_KEYUP = 0x0291;
pub const WM_MOUSEHOVER = 0x02A1;
pub const WM_MOUSELEAVE = 0x02A3;
pub const WM_NCMOUSEHOVER = 0x02A0;
pub const WM_NCMOUSELEAVE = 0x02A2;
pub const WM_WTSSESSION_CHANGE = 0x02B1;
pub const WM_TABLET_FIRST = 0x02c0;
pub const WM_TABLET_LAST = 0x02df;
pub const WM_DPICHANGED = 0x02e0;
pub const WM_CUT = 0x0300;
pub const WM_COPY = 0x0301;
pub const WM_PASTE = 0x0302;
pub const WM_CLEAR = 0x0303;
pub const WM_UNDO = 0x0304;
pub const WM_RENDERFORMAT = 0x0305;
pub const WM_RENDERALLFORMATS = 0x0306;
pub const WM_DESTROYCLIPBOARD = 0x0307;
pub const WM_DRAWCLIPBOARD = 0x0308;
pub const WM_PAINTCLIPBOARD = 0x0309;
pub const WM_VSCROLLCLIPBOARD = 0x030A;
pub const WM_SIZECLIPBOARD = 0x030B;
pub const WM_ASKCBFORMATNAME = 0x030C;
pub const WM_CHANGECBCHAIN = 0x030D;
pub const WM_HSCROLLCLIPBOARD = 0x030E;
pub const WM_QUERYNEWPALETTE = 0x030F;
pub const WM_PALETTEISCHANGING = 0x0310;
pub const WM_PALETTECHANGED = 0x0311;
pub const WM_HOTKEY = 0x0312;
pub const WM_PRINT = 0x0317;
pub const WM_PRINTCLIENT = 0x0318;
pub const WM_APPCOMMAND = 0x0319;
pub const WM_THEMECHANGED = 0x031A;
pub const WM_CLIPBOARDUPDATE = 0x031d;
pub const WM_DWMCOMPOSITIONCHANGED = 0x031e;
pub const WM_DWMNCRENDERINGCHANGED = 0x031f;
pub const WM_DWMCOLORIZATIONCOLORCHANGED = 0x0320;
pub const WM_DWMWINDOWMAXIMIZEDCHANGE = 0x0321;
pub const WM_DWMSENDICONICTHUMBNAIL = 0x0323;
pub const WM_DWMSENDICONICLIVEPREVIEWBITMAP = 0x0326;
pub const WM_GETTITLEBARINFOEX = 0x033f;
pub const WM_HANDHELDFIRST = 0x0358;
pub const WM_HANDHELDLAST = 0x035F;
pub const WM_AFXFIRST = 0x0360;
pub const WM_AFXLAST = 0x037F;
pub const WM_PENWINFIRST = 0x0380;
pub const WM_PENWINLAST = 0x038F;
pub const WM_APP = 0x8000;
pub const WM_USER = 0x0400;

pub const WS_OVERLAPPED = 0x00000000;
pub const WS_POPUP = 0x80000000;
pub const WS_CHILD = 0x40000000;
pub const WS_MINIMIZE = 0x20000000;
pub const WS_VISIBLE = 0x10000000;
pub const WS_DISABLED = 0x08000000;
pub const WS_CLIPSIBLINGS = 0x04000000;
pub const WS_CLIPCHILDREN = 0x02000000;
pub const WS_MAXIMIZE = 0x01000000;
pub const WS_CAPTION = 0x00C00000;
pub const WS_BORDER = 0x00800000;
pub const WS_DLGFRAME = 0x00400000;
pub const WS_VSCROLL = 0x00200000;
pub const WS_HSCROLL = 0x00100000;
pub const WS_SYSMENU = 0x00080000;
pub const WS_THICKFRAME = 0x00040000;
pub const WS_GROUP = 0x00020000;
pub const WS_TABSTOP = 0x00010000;
pub const WS_MINIMIZEBOX = 0x00020000;
pub const WS_MAXIMIZEBOX = 0x00010000;
pub const WS_TILED = WS_OVERLAPPED;
pub const WS_ICONIC = WS_MINIMIZE;
pub const WS_SIZEBOX = WS_THICKFRAME;
pub const WS_TILEDWINDOW = WS_OVERLAPPEDWINDOW;
pub const WS_OVERLAPPEDWINDOW = (WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX);
pub const WS_POPUPWINDOW = (WS_POPUP | WS_BORDER | WS_SYSMENU);
pub const WS_CHILDWINDOW = (WS_CHILD);
pub const WS_EX_DLGMODALFRAME = 0x00000001;
pub const WS_EX_NOPARENTNOTIFY = 0x00000004;
pub const WS_EX_TOPMOST = 0x00000008;
pub const WS_EX_ACCEPTFILES = 0x00000010;
pub const WS_EX_TRANSPARENT = 0x00000020;
pub const WS_EX_MDICHILD = 0x00000040;
pub const WS_EX_TOOLWINDOW = 0x00000080;
pub const WS_EX_WINDOWEDGE = 0x00000100;
pub const WS_EX_CLIENTEDGE = 0x00000200;
pub const WS_EX_CONTEXTHELP = 0x00000400;
pub const WS_EX_RIGHT = 0x00001000;
pub const WS_EX_LEFT = 0x00000000;
pub const WS_EX_RTLREADING = 0x00002000;
pub const WS_EX_LTRREADING = 0x00000000;
pub const WS_EX_LEFTSCROLLBAR = 0x00004000;
pub const WS_EX_RIGHTSCROLLBAR = 0x00000000;
pub const WS_EX_CONTROLPARENT = 0x00010000;
pub const WS_EX_STATICEDGE = 0x00020000;
pub const WS_EX_APPWINDOW = 0x00040000;
pub const WS_EX_OVERLAPPEDWINDOW = (WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE);
pub const WS_EX_PALETTEWINDOW = (WS_EX_WINDOWEDGE | WS_EX_TOOLWINDOW | WS_EX_TOPMOST);
pub const WS_EX_LAYERED = 0x00080000;
pub const WS_EX_NOINHERITLAYOUT = 0x00100000;
pub const WS_EX_NOREDIRECTIONBITMAP = 0x00200000;
pub const WS_EX_LAYOUTRTL = 0x00400000;
pub const WS_EX_COMPOSITED = 0x02000000;
pub const WS_EX_NOACTIVATE = 0x08000000;

// Structs
pub const LUID = extern struct {
    LowPart: DWORD,
    HighPart: LONG,
};
pub const MSG = extern struct {
    hwnd: HWND,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    time: DWORD,
    pt: POINT,
};
pub const RECT = extern struct {
    left: LONG,
    top: LONG,
    right: LONG,
    bottom: LONG,
};
pub const SIZE = extern struct {
    cx: LONG,
    cy: LONG,
};
pub const WNDCLASSEX = extern struct {
    cbSize: UINT,
    style: UINT,
    lpfnWndProc: *const fn (hWnd: ?HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(WINAPI) LRESULT,
    cbClsExtra: i32,
    cbWndExtra: i32,
    hInstance: ?HINSTANCE,
    hIcon: ?HICON,
    hCursor: ?HCURSOR,
    hbrBackground: ?HBRUSH,
    lpszMenuName: ?LPCSTR,
    lpszClassName: ?LPCSTR,
    hIconSm: ?HICON,
};

// Functions
pub const CreateWindowEx = CreateWindowExA;
extern "user32" fn CreateWindowExA(dxExStyle: DWORD, lpClassName: LPCSTR, lpWindowName: LPCSTR, dwStyle: DWORD, x: i32, y: i32, nWidth: i32, nHeight: i32, hWndParent: ?HWND, hMenu: ?HMENU, hInstance: HINSTANCE, lpParam: ?*anyopaque) callconv(WINAPI) ?HWND;
pub const DefWindowProc = DefWindowProcA;
extern "user32" fn DefWindowProcA(hWnd: ?HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(WINAPI) LRESULT;
pub const DispatchMessage = DispatchMessageA;
extern "user32" fn DispatchMessageA(lpMsg: *const MSG) callconv(WINAPI) LRESULT;
pub extern "kernel32" fn GetLastError() callconv(WINAPI) DWORD;
pub const GetModuleHandle = GetModuleHandleA;
extern "kernel32" fn GetModuleHandleA(lpModuleName: ?LPCSTR) callconv(WINAPI) ?HMODULE;
pub const GetProp = GetPropA;
extern "user32" fn GetPropA(hWnd: ?HWND, lpString: LPCSTR) callconv(WINAPI) ?HANDLE;
pub const FormatMessage = FormatMessageA;
extern "kernel32" fn FormatMessageA(dwFlags: DWORD, lpSource: ?*anyopaque, dwMessageId: DWORD, dwLanguageId: DWORD, lpBuffer: LPSTR, nSize: DWORD, Arguments: ?*anyopaque) callconv(WINAPI) DWORD;
pub const PeekMessage = PeekMessageA;
extern "user32" fn PeekMessageA(lpMsg: *MSG, hWnd: ?HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT) callconv(WINAPI) WINBOOL;
pub const RegisterClassEx = RegisterClassExA;
extern "user32" fn RegisterClassExA(class: *const WNDCLASSEX) callconv(WINAPI) ATOM;
pub const SetProp = SetPropA;
extern "user32" fn SetPropA(hWnd: HWND, lpString: LPCSTR, hData: HANDLE) callconv(WINAPI) WINBOOL;
pub extern "user32" fn ShowWindow(hWnd: HWND, nCmdShow: i32) callconv(WINAPI) WINBOOL;
pub extern "user32" fn TranslateMessage(lpMsg: *MSG) callconv(WINAPI) WINBOOL;

// COM objects
pub const IUnknown = extern struct {
    vtable: *VTable,

    pub const QueryInterface = IUnknown.Methods(@This()).QueryInterface;
    pub const AddRef = IUnknown.Methods(@This()).AddRef;
    pub const Release = IUnknown.Methods(@This()).Release;

    pub fn Methods(comptime T: type) type {
        return extern struct {
            pub inline fn QueryInterface(self: *T, riid: *const GUID, object: ?*?*anyopaque) HRESULT {
                return @as(*const IUnknown.VTable, @ptrCast(self.vtable)).QueryInterface(@ptrCast(self), riid, object);
            }
            pub inline fn AddRef(self: *T) ULONG {
                return @as(*const IUnknown.VTable, @ptrCast(self.vtable)).AddRef(@ptrCast(self));
            }
            pub inline fn Release(self: *T) ULONG {
                return @as(*const IUnknown.VTable, @ptrCast(self.vtable)).Release(@ptrCast(self));
            }
        };
    }

    pub const VTable = extern struct {
        QueryInterface: *const fn (self: *IUnknown, riid: *const GUID, object: ?*?*anyopaque) callconv(WINAPI) HRESULT,
        AddRef: *const fn (self: *IUnknown) callconv(WINAPI) ULONG,
        Release: *const fn (self: *IUnknown) callconv(WINAPI) ULONG,
    };
};
