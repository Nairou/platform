const std = @import("std");
const builtin = @import("builtin");
const harfbuzz = @import("harfbuzz");
const freetype = @import("freetype");
const platform = @import("platform");
const gl = @import("zgl");

pub const fp246 = i32;

pub const Color = packed struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
};

pub const BoxInstance = packed struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    cornerRadius: f32,
    fillColor: Color,
    borderWidth: f32,
    borderColor: Color,
};

pub const TextInstance = extern struct {
    position: [2]f32,
    size: [2]f32,
    texture: [2]f32,
    color: Color,
};

pub const TempVertex = extern struct {
    position: [2]f32,
    texture: [2]f32,
};

var windowWidth: u32 = 1280;
var windowHeight: u32 = 720;
var gradient: f32 = 0;

var boxVao: gl.VertexArray = undefined;
var boxVbo: gl.Buffer = undefined;
var boxBuffer: [12]f32 = [_]f32{
    1,  -1,
    -1, -1,
    -1, 1,
    -1, 1,
    1,  1,
    1,  -1,
};
var boxInstanceVbo: gl.Buffer = undefined;
var boxInstanceBuffer: [5]BoxInstance = [_]BoxInstance{
    .{ .x = 200, .y = 200, .width = 300, .height = 200, .cornerRadius = 10, .fillColor = .{ .r = 0.25, .g = 0.5, .b = 0.65, .a = 1 }, .borderWidth = 2, .borderColor = .{ .r = 1, .g = 1, .b = 1, .a = 1 } },
    .{ .x = 400, .y = 400, .width = 50, .height = 500, .cornerRadius = 10, .fillColor = .{ .r = 0.25, .g = 0.5, .b = 0.65, .a = 1 }, .borderWidth = 5, .borderColor = .{ .r = 0.75, .g = 0, .b = 0, .a = 1 } },
    .{ .x = 800, .y = 300, .width = 50, .height = 50, .cornerRadius = 25, .fillColor = .{ .r = 0.25, .g = 0.5, .b = 0.65, .a = 1 }, .borderWidth = 0, .borderColor = .{ .r = 0.5, .g = 0.5, .b = 0.5, .a = 0.5 } },
    .{ .x = 800, .y = 350, .width = 50, .height = 50, .cornerRadius = 0, .fillColor = .{ .r = 0.25, .g = 0.5, .b = 0.65, .a = 1 }, .borderWidth = 10, .borderColor = .{ .r = 0.5, .g = 0.5, .b = 0.5, .a = 0.5 } },
    .{ .x = 800, .y = 600, .width = 50, .height = 50, .cornerRadius = 25, .fillColor = .{ .r = 0.25, .g = 0.5, .b = 0.65, .a = 1 }, .borderWidth = 10, .borderColor = .{ .r = 0.5, .g = 0.5, .b = 0.5, .a = 0.5 } },
};
var boxVertexShader: gl.Shader = undefined;
var boxFragmentShader: gl.Shader = undefined;
var boxShaderProgram: gl.Program = undefined;
var boxUniformModelViewProj: ?u32 = undefined;
var boxUniformWindowSize: ?u32 = undefined;

var ftVao: gl.VertexArray = undefined;
var ftVbo: gl.Buffer = undefined;
var ftBuffer: [6]TempVertex = [_]TempVertex{
    .{ .position = .{ 1424, 400 }, .texture = .{ 1, 0 } },
    .{ .position = .{ 400, 400 }, .texture = .{ 0, 0 } },
    .{ .position = .{ 400, 1424 }, .texture = .{ 0, 1 } },
    .{ .position = .{ 400, 1424 }, .texture = .{ 0, 1 } },
    .{ .position = .{ 1424, 1424 }, .texture = .{ 1, 1 } },
    .{ .position = .{ 1424, 400 }, .texture = .{ 1, 0 } },
};
var ftVertexShader: gl.Shader = undefined;
var ftFragmentShader: gl.Shader = undefined;
var ftShaderProgram: gl.Program = undefined;
var ftUniformModelViewProj: ?u32 = undefined;
var ftUniformWindowSize: ?u32 = undefined;
var ftUniformTextureSampler0: ?u32 = undefined;

var textVao: gl.VertexArray = undefined;
var textVbo: gl.Buffer = undefined;
var textBuffer: [8]f32 = [_]f32{
    1, 0,
    0, 0,
    0, 1,
    1, 1,
};
var textInstanceVbo: gl.Buffer = undefined;
var textInstanceBuffer: std.ArrayListUnmanaged(TextInstance) = .empty;
var textVertexShader: gl.Shader = undefined;
var textFragmentShader: gl.Shader = undefined;
var textShaderProgram: gl.Program = undefined;
var textUniformModelViewProj: ?u32 = undefined;
var textUniformWindowSize: ?u32 = undefined;
var textUniformTextureSampler0: ?u32 = undefined;

var atlas: FontTextureAtlas = .{};
var atlasTextureId: gl.Texture = undefined;

fn hbCallbackReferenceTables(face: ?*harfbuzz.c.hb_face_t, tag: harfbuzz.c.hb_tag_t, user_data: ?*anyopaque) callconv(.C) ?*harfbuzz.c.hb_blob_t {
    _ = face;
    if (user_data == null) {
        return null;
    }

    const data: *CallbackFaceAllocator = @alignCast(@ptrCast(user_data.?));
    var length: freetype.c.FT_ULong = 0;
    if (freetype.c.FT_Load_Sfnt_Table(data.face, tag, 0, null, &length) != 0) {
        return null;
    }
    std.log.debug("FT tag {d} length = {d}", .{ tag, length });

    const buffer = data.allocator.alloc(u8, length) catch return null;

    if (freetype.c.FT_Load_Sfnt_Table(data.face, tag, 0, buffer.ptr, &length) != 0) {
        data.allocator.free(buffer);
        return null;
    }

    return harfbuzz.c.hb_blob_create(buffer.ptr, @intCast(length), harfbuzz.c.HB_MEMORY_MODE_WRITABLE, buffer.ptr, null);
}

const CallbackFaceAllocator = struct {
    allocator: std.mem.Allocator,
    face: freetype.c.FT_Face,
};

pub fn main() anyerror!void {
    _ = try platform.init(std.heap.page_allocator);
    defer platform.deinit();

    var fontAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer fontAllocator.deinit();

    const glSetup = struct {
        pub fn glGetProcAddress(comptime _: type, proc: [:0]const u8) ?*const anyopaque {
            return platform.getProcAddress(proc);
        }
    };

    if (builtin.os.tag == .linux) {
        gl.loadExtensions(void, glSetup.glGetProcAddress) catch return error.CantLoadGlExtensions;
    }

    const window = try platform.Window.create(windowWidth, windowHeight, "platform", "Example!");
    std.log.debug("Opened window, id = {}", .{window.id});

    { // Temp init
        boxVao = gl.genVertexArray();
        boxVao.bind();
        boxVbo = gl.genBuffer();
        boxVbo.bind(gl.BufferTarget.array_buffer);
        gl.bufferData(gl.BufferTarget.array_buffer, f32, boxBuffer[0..12], gl.BufferUsage.static_draw);
        gl.enableVertexAttribArray(0);
        gl.vertexAttribDivisor(0, 0);
        gl.vertexAttribPointer(0, 2, gl.Type.float, false, 2 * @sizeOf(f32), 0);
        boxInstanceVbo = gl.genBuffer();
        boxInstanceVbo.bind(gl.BufferTarget.array_buffer);
        gl.enableVertexAttribArray(1);
        gl.vertexAttribDivisor(1, 1);
        gl.vertexAttribPointer(1, 4, gl.Type.float, false, @sizeOf(BoxInstance), @offsetOf(BoxInstance, "x"));
        gl.enableVertexAttribArray(2);
        gl.vertexAttribDivisor(2, 1);
        gl.vertexAttribPointer(2, 1, gl.Type.float, false, @sizeOf(BoxInstance), @offsetOf(BoxInstance, "cornerRadius"));
        gl.enableVertexAttribArray(3);
        gl.vertexAttribDivisor(3, 1);
        gl.vertexAttribPointer(3, 4, gl.Type.float, false, @sizeOf(BoxInstance), @offsetOf(BoxInstance, "fillColor"));
        gl.enableVertexAttribArray(4);
        gl.vertexAttribDivisor(4, 1);
        gl.vertexAttribPointer(4, 1, gl.Type.float, false, @sizeOf(BoxInstance), @offsetOf(BoxInstance, "borderWidth"));
        gl.enableVertexAttribArray(5);
        gl.vertexAttribDivisor(5, 1);
        gl.vertexAttribPointer(5, 4, gl.Type.float, false, @sizeOf(BoxInstance), @offsetOf(BoxInstance, "borderColor"));

        const glslFileBuffer =
            \\struct vertexData {
            \\    vec2 position;
            \\    vec2 origin;
            \\    vec2 radius;
            \\    float cornerRadius;
            \\    vec4 fillColor;
            \\    float borderWidth;
            \\    vec4 borderColor;
            \\    //vec2 texture0;
            \\};
            \\
            \\
            \\#ifdef COMPILE_VERT
            \\
            \\
            \\uniform ivec2 WindowSize;
            \\
            \\layout(location=0) in vec2 quad;
            \\layout(location=1) in vec4 box;
            \\layout(location=2) in float cornerRadius;
            \\layout(location=3) in vec4 fillColor;
            \\layout(location=4) in float borderWidth;
            \\layout(location=5) in vec4 borderColor;
            \\
            \\out vertexData data;
            \\
            \\void main()
            \\{
            \\    data.radius = box.zw * 0.5;
            \\    data.origin = box.xy + data.radius;
            \\    data.position = data.origin + data.radius * quad;
            \\    vec2 pos = 2.0 * data.position / WindowSize - 1.0;
            \\    gl_Position = vec4( pos, 0, 1 );
            \\
            \\    data.cornerRadius = cornerRadius;
            \\    data.fillColor = fillColor;
            \\    data.borderWidth = borderWidth;
            \\    data.borderColor = borderColor;
            \\}
            \\
            \\
            \\#endif
            \\#ifdef COMPILE_FRAG
            \\
            \\
            \\uniform sampler2D textureSampler;
            \\
            \\in vertexData data;
            \\
            \\layout(location=0) out vec4 outColor;
            \\
            \\float RoundedRectSDF(vec2 sample_pos, vec2 rect_center, vec2 radius, float r)
            \\{
            \\  vec2 d2 = (abs(rect_center - sample_pos) - radius + vec2(r, r));
            \\  return min(max(d2.x, d2.y), 0.0) + length(max(d2, 0.0)) - r;
            \\
            \\  //vec2 q = abs(p)-b+r;
            \\  //return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r;
            \\}
            \\
            \\void main()
            \\{
            \\    float d = RoundedRectSDF( data.position, data.origin, data.radius, data.cornerRadius );
            \\    float b = abs( d ) - data.borderWidth;
            \\    outColor = vec4(0,0,0,0);//data.borderWidth > 0.0 ? mix( data.fillColor, data.borderColor, 1.0 - smoothstep( 0.0, 0.9, max( 0.0, b + 0.5 )) ) : data.fillColor;
            \\    outColor.a = mix( 1.0, 0.0, smoothstep( 0.0, 1.0, max( 0.0, d + 0.5 )) );
            \\    //outColor.rgb *= 0.8 + 0.2 * cos( 300.0 * d );
            \\}
            \\
            \\
            \\#endif
        ;

        var logBuffer: [4096]u8 = undefined;
        var logBufferWrapper = std.heap.FixedBufferAllocator.init(&logBuffer);
        const logBufferAllocator = logBufferWrapper.allocator();

        // Vertex shader
        boxVertexShader = gl.createShader(.vertex);
        errdefer boxVertexShader.delete();
        const vertSource = [_][]const u8{ "#version 450\n", "#define COMPILE_VERT\n", glslFileBuffer };
        boxVertexShader.source(3, &vertSource);
        boxVertexShader.compile();
        if (boxVertexShader.get(.compile_status) == 0) {
            const message = try boxVertexShader.getCompileLog(logBufferAllocator);
            defer logBufferAllocator.free(message);
            std.log.err("Error compiling vertex shader: {s}", .{message});
            return error.ShaderCompile;
        }

        // Fragment shader
        boxFragmentShader = gl.createShader(.fragment);
        errdefer boxFragmentShader.delete();
        const fragSource = [_][]const u8{ "#version 450\n", "#define COMPILE_FRAG\n", glslFileBuffer };
        boxFragmentShader.source(3, &fragSource);
        boxFragmentShader.compile();
        if (boxFragmentShader.get(.compile_status) == 0) {
            const message = try boxFragmentShader.getCompileLog(logBufferAllocator);
            defer logBufferAllocator.free(message);
            std.log.err("Error compiling fragment shader: {s}", .{message});
            return error.ShaderCompile;
        }

        // Shader program
        boxShaderProgram = gl.createProgram();
        boxShaderProgram.attach(boxVertexShader);
        boxShaderProgram.attach(boxFragmentShader);
        boxShaderProgram.link();
        if (boxShaderProgram.get(.link_status) == 0) {
            const message = try boxShaderProgram.getCompileLog(logBufferAllocator);
            defer logBufferAllocator.free(message);
            std.log.err("Error linking shader program: {s}", .{message});
            return error.ShaderCompile;
        }

        boxUniformModelViewProj = boxShaderProgram.uniformLocation("ModelViewProj");
        boxUniformWindowSize = boxShaderProgram.uniformLocation("WindowSize");
    }

    {
        ftVao = gl.genVertexArray();
        ftVao.bind();
        ftVbo = gl.genBuffer();
        ftVbo.bind(gl.BufferTarget.array_buffer);
        gl.bufferData(gl.BufferTarget.array_buffer, TempVertex, &ftBuffer, gl.BufferUsage.static_draw);
        gl.enableVertexAttribArray(0);
        gl.vertexAttribPointer(0, 2, .float, false, @sizeOf(TempVertex), @offsetOf(TempVertex, "position"));
        gl.enableVertexAttribArray(1);
        gl.vertexAttribPointer(1, 2, .float, false, @sizeOf(TempVertex), @offsetOf(TempVertex, "texture"));

        const glslFileBuffer =
            \\struct vertexData {
            \\    vec2 texture;
            \\};
            \\
            \\
            \\#ifdef COMPILE_VERT
            \\
            \\
            \\uniform ivec2 WindowSize;
            \\
            \\layout(location=0) in vec2 position;
            \\layout(location=1) in vec2 texture;
            \\
            \\out vertexData data;
            \\
            \\void main()
            \\{
            \\    vec2 pos = 2.0 * position / WindowSize - 1.0;
            \\    pos.y *= -1;
            \\    gl_Position = vec4( pos, 0, 1 );
            \\    data.texture = texture;
            \\}
            \\
            \\
            \\#endif
            \\#ifdef COMPILE_FRAG
            \\
            \\
            \\uniform sampler2D TextureSampler;
            \\
            \\in vertexData data;
            \\
            \\layout(location=0) out vec4 outColor;
            \\
            \\void main()
            \\{
            \\    vec4 t = texture( TextureSampler, data.texture );
            \\    outColor = vec4( 1, 1, 1, t.r );
            \\}
            \\
            \\
            \\#endif
        ;

        var logBuffer: [4096]u8 = undefined;
        var logBufferWrapper = std.heap.FixedBufferAllocator.init(&logBuffer);
        const logBufferAllocator = logBufferWrapper.allocator();

        // Vertex shader
        ftVertexShader = gl.createShader(.vertex);
        errdefer ftVertexShader.delete();
        const vertSource = [_][]const u8{ "#version 450\n", "#define COMPILE_VERT\n", glslFileBuffer };
        ftVertexShader.source(3, &vertSource);
        ftVertexShader.compile();
        if (ftVertexShader.get(.compile_status) == 0) {
            const message = try ftVertexShader.getCompileLog(logBufferAllocator);
            defer logBufferAllocator.free(message);
            std.log.err("Error compiling vertex shader: {s}", .{message});
            return error.ShaderCompile;
        }

        // Fragment shader
        ftFragmentShader = gl.createShader(.fragment);
        errdefer ftFragmentShader.delete();
        const fragSource = [_][]const u8{ "#version 450\n", "#define COMPILE_FRAG\n", glslFileBuffer };
        ftFragmentShader.source(3, &fragSource);
        ftFragmentShader.compile();
        if (ftFragmentShader.get(.compile_status) == 0) {
            const message = try ftFragmentShader.getCompileLog(logBufferAllocator);
            defer logBufferAllocator.free(message);
            std.log.err("Error compiling fragment shader: {s}", .{message});
            return error.ShaderCompile;
        }

        // Shader program
        ftShaderProgram = gl.createProgram();
        ftShaderProgram.attach(ftVertexShader);
        ftShaderProgram.attach(ftFragmentShader);
        ftShaderProgram.link();
        if (ftShaderProgram.get(.link_status) == 0) {
            const message = try ftShaderProgram.getCompileLog(logBufferAllocator);
            defer logBufferAllocator.free(message);
            std.log.err("Error linking shader program: {s}", .{message});
            return error.ShaderCompile;
        }

        ftUniformModelViewProj = ftShaderProgram.uniformLocation("ModelViewProj");
        ftUniformWindowSize = ftShaderProgram.uniformLocation("WindowSize");
        ftUniformTextureSampler0 = ftShaderProgram.uniformLocation("TextureSampler");

        atlasTextureId = gl.genTexture();
        atlasTextureId.bind(.@"2d");
        gl.texParameter(.@"2d", .min_filter, gl.TextureParameterType(.min_filter).nearest);
        gl.texParameter(.@"2d", .mag_filter, gl.TextureParameterType(.mag_filter).nearest);
        gl.texParameter(.@"2d", .wrap_r, gl.TextureParameterType(.wrap_r).repeat);
        gl.texParameter(.@"2d", .wrap_s, gl.TextureParameterType(.wrap_s).repeat);
        gl.texParameter(.@"2d", .wrap_t, gl.TextureParameterType(.wrap_t).repeat);
    }

    { // Text init
        textVao = gl.genVertexArray();
        textVao.bind();
        textVbo = gl.genBuffer();
        textVbo.bind(gl.BufferTarget.array_buffer);
        gl.bufferData(gl.BufferTarget.array_buffer, f32, textBuffer[0..8], gl.BufferUsage.static_draw);
        gl.enableVertexAttribArray(0);
        gl.vertexAttribDivisor(0, 0);
        gl.vertexAttribPointer(0, 2, gl.Type.float, false, 2 * @sizeOf(f32), 0);
        textInstanceVbo = gl.genBuffer();
        textInstanceVbo.bind(gl.BufferTarget.array_buffer);
        gl.enableVertexAttribArray(1);
        gl.vertexAttribDivisor(1, 1);
        gl.vertexAttribPointer(1, 4, gl.Type.float, false, @sizeOf(TextInstance), @offsetOf(TextInstance, "position"));
        gl.enableVertexAttribArray(2);
        gl.vertexAttribDivisor(2, 1);
        gl.vertexAttribPointer(2, 2, gl.Type.float, false, @sizeOf(TextInstance), @offsetOf(TextInstance, "texture"));
        gl.enableVertexAttribArray(3);
        gl.vertexAttribDivisor(3, 1);
        gl.vertexAttribPointer(3, 4, gl.Type.float, false, @sizeOf(TextInstance), @offsetOf(TextInstance, "color"));

        const glslFileBuffer =
            \\struct vertexData {
            \\    vec4 color;
            \\    vec2 texture0;
            \\};
            \\
            \\
            \\#ifdef COMPILE_VERT
            \\
            \\
            \\uniform ivec2 WindowSize;
            \\
            \\layout(location=0) in vec2 quad;
            \\layout(location=1) in vec4 box;
            \\layout(location=2) in vec2 texture;
            \\layout(location=3) in vec4 color;
            \\
            \\out vertexData data;
            \\
            \\void main()
            \\{
            \\    vec2 position = box.xy + box.zw * quad;
            \\    vec2 pos = 2.0 * position / WindowSize - 1.0;
            \\    pos.y *= -1;
            \\    gl_Position = vec4( pos, 0, 1 );
            \\    data.color = color;
            \\    data.texture0 = (texture + box.zw * quad) / 1024.0;
            \\}
            \\
            \\
            \\#endif
            \\#ifdef COMPILE_FRAG
            \\
            \\
            \\uniform sampler2D textureSampler;
            \\
            \\in vertexData data;
            \\
            \\layout(location=0) out vec4 outColor;
            \\
            \\void main()
            \\{
            \\    vec4 t = texture( textureSampler, data.texture0 );
            \\    outColor = data.color;
            \\    outColor.a *= t.r;
            \\}
            \\
            \\
            \\#endif
        ;

        var logBuffer: [4096]u8 = undefined;
        var logBufferWrapper = std.heap.FixedBufferAllocator.init(&logBuffer);
        const logBufferAllocator = logBufferWrapper.allocator();

        // Vertex shader
        textVertexShader = gl.createShader(.vertex);
        errdefer textVertexShader.delete();
        const vertSource = [_][]const u8{ "#version 450\n", "#define COMPILE_VERT\n", glslFileBuffer };
        textVertexShader.source(3, &vertSource);
        textVertexShader.compile();
        if (textVertexShader.get(.compile_status) == 0) {
            const message = try textVertexShader.getCompileLog(logBufferAllocator);
            defer logBufferAllocator.free(message);
            std.log.err("Error compiling vertex shader: {s}", .{message});
            return error.ShaderCompile;
        }

        // Fragment shader
        textFragmentShader = gl.createShader(.fragment);
        errdefer textFragmentShader.delete();
        const fragSource = [_][]const u8{ "#version 450\n", "#define COMPILE_FRAG\n", glslFileBuffer };
        textFragmentShader.source(3, &fragSource);
        textFragmentShader.compile();
        if (textFragmentShader.get(.compile_status) == 0) {
            const message = try textFragmentShader.getCompileLog(logBufferAllocator);
            defer logBufferAllocator.free(message);
            std.log.err("Error compiling fragment shader: {s}", .{message});
            return error.ShaderCompile;
        }

        // Shader program
        textShaderProgram = gl.createProgram();
        textShaderProgram.attach(textVertexShader);
        textShaderProgram.attach(textFragmentShader);
        textShaderProgram.link();
        if (textShaderProgram.get(.link_status) == 0) {
            const message = try textShaderProgram.getCompileLog(logBufferAllocator);
            defer logBufferAllocator.free(message);
            std.log.err("Error linking shader program: {s}", .{message});
            return error.ShaderCompile;
        }

        textUniformModelViewProj = textShaderProgram.uniformLocation("ModelViewProj");
        textUniformWindowSize = textShaderProgram.uniformLocation("WindowSize");
        textUniformTextureSampler0 = textShaderProgram.uniformLocation("TextureSampler");
    }

    const testFont1 = try Font.create(fontAllocator.allocator(), "Roboto-Medium.ttf", 48, 72);
    defer testFont1.free();

    draw(window.id);

    var running = true;
    while (running) {
        while (platform.readNextEvent(true)) |event| {
            switch (event) {
                .window_refresh => |window_refresh| {
                    gradient += 0.001;

                    textInstanceBuffer.clearRetainingCapacity();
                    var sampleTextBuffer: [1024]u8 = @splat(0);
                    const sampleTextX: i32 = @intFromFloat((100.0 + @sin(gradient) * 50.0) * 64);
                    const sampleText = try std.fmt.bufPrintZ(&sampleTextBuffer, "Hello, World! ... x = {d}, gradient = {d}", .{ sampleTextX, gradient });
                    try testFont1.shapeText(sampleText, sampleTextX, 100 * 64, &atlas, &textInstanceBuffer);

                    const testFont2 = try Font.create(fontAllocator.allocator(), "Roboto-Medium.ttf", 24, 72);
                    defer testFont2.free();
                    try testFont2.shapeText("Hello, World!", sampleTextX, 150 * 64, &atlas, &textInstanceBuffer);

                    const testFont3 = try Font.create(fontAllocator.allocator(), "Roboto-Medium.ttf", 12, 72);
                    defer testFont3.free();
                    try testFont3.shapeText("Hello, World!", sampleTextX, 180 * 64, &atlas, &textInstanceBuffer);

                    draw(window_refresh.window);
                },
                .window_close => |_| {
                    running = false;
                    std.log.debug("Window wants to close", .{});
                },
                .window_size => |window_size| {
                    std.log.debug("Window resized to {d}x{d}", .{ window_size.width, window_size.height });
                    windowWidth = window_size.width;
                    windowHeight = window_size.height;
                    gl.viewport(0, 0, window_size.width, window_size.height);
                },
                else => std.log.debug("Unknown event: {}", .{event}),
            }
        }
    }
}

const FontTextureAtlas = struct {
    glyphMap: std.AutoHashMapUnmanaged(Key, Slot) = .empty,
    shelves: std.ArrayListUnmanaged(Shelf) = .empty,
    textureBuffer: [TextureSize * TextureSize]u8 = @splat(0),
    textureDirty: bool = false,

    const TextureSize = 1024;

    pub const Key = struct {
        font: u64,
        glyph: u32,
        offsetIndex: u4,
    };
    pub const Slot = struct {
        position: [2]u16,
        size: [2]u16,
        offset: [2]i16,
    };
    pub const Shelf = struct {
        offset: u16,
        height: u16,
        remaining: u16,
    };

    pub fn getGlyph(self: *FontTextureAtlas, font: u64, glyph: u32, offsetIndex: u4) ?Slot {
        const key: Key = .{ .font = font, .glyph = glyph, .offsetIndex = offsetIndex };
        return self.glyphMap.get(key);
    }

    pub fn insertGlyph(self: *FontTextureAtlas, allocator: std.mem.Allocator, font: u64, glyph: u32, offsetIndex: u4, width: u16, height: u16, top: i16, left: i16) !Slot {
        std.log.debug("Insert glyph {d}, width = {d}, height = {d}", .{ glyph, width, height });
        const slotWidth = width + 1;
        const slotHeight = ((height + 4) / 5) * 5 + 1;
        std.debug.assert(slotWidth < TextureSize);
        std.debug.assert(slotHeight < TextureSize);
        const key: Key = .{ .font = font, .glyph = glyph, .offsetIndex = offsetIndex };
        if (self.glyphMap.get(key)) |slot| {
            std.log.debug("Already exists in atlas: font = {d}, glyph = {d}", .{ font, glyph });
            return slot;
        }

        var nextOffset: u16 = 0;
        const slot = for (self.shelves.items, 0..) |*shelf, index| {
            std.debug.assert(shelf.offset == nextOffset);
            if (shelf.height >= slotHeight and shelf.remaining >= slotWidth) {
                std.log.debug("Glyph height {d} will fit in shelf {d} height {d}", .{ slotHeight, index, shelf.height });
                defer shelf.remaining -= slotWidth;
                break Slot{ .position = .{ TextureSize - shelf.remaining, shelf.offset }, .size = .{ width, height }, .offset = .{ left, top } };
            }
            nextOffset += shelf.height;
        } else blk: {
            std.log.debug("Glyph height {d} fit no shelves, adding new shelf, offset = {d}", .{ height, nextOffset });
            std.debug.assert(nextOffset <= TextureSize);
            if (TextureSize - nextOffset < slotHeight) {
                return error.AtlasIsFull;
            }

            const shelf = try self.shelves.addOne(allocator);
            shelf.* = .{
                .offset = nextOffset,
                .height = slotHeight,
                .remaining = TextureSize - slotWidth,
            };
            break :blk Slot{ .position = .{ 0, shelf.offset }, .size = .{ width, height }, .offset = .{ left, top } };
        };

        std.log.debug("Added to atlas: font = {d}, glyph = {d}, data = {}", .{ font, glyph, slot });

        try self.glyphMap.put(allocator, key, slot);
        return slot;
    }
};

//const FontBackendFreetype = struct {
//    library: freetype.c.FT_Library,
//
//    pub fn init(self: *FontBackendFreetype) void {
//        _ = freetype.c.FT_Init_FreeType(&self.library);
//    }
//};
//pub fn FontBackendType() type {
//    return FontBackendFreetype;
//}
//const fontBackend: FontBackendType() = null;
var ftLib: freetype.c.FT_Library = null;

const Font = struct {
    allocator: std.mem.Allocator,
    id: u64,
    ftFace: freetype.c.FT_Face,
    hbFont: ?*harfbuzz.c.hb_font_t,
    callbackData: CallbackFaceAllocator,

    pub fn create(allocator: std.mem.Allocator, fileName: [:0]const u8, pointSize: u32, dpi: u32) !*Font {
        // TODO: Error handling
        if (ftLib == null) {
            _ = freetype.c.FT_Init_FreeType(&ftLib);
        }

        const fingerprint = .{
            .fileName = fileName,
            .pointSize = pointSize,
            .dpi = dpi,
        };
        var newFont = try allocator.create(Font);
        newFont.allocator = allocator;
        newFont.id = std.hash.Wyhash.hash(0, std.mem.asBytes(&fingerprint));

        _ = freetype.c.FT_New_Face(ftLib, fileName, 0, &newFont.ftFace);
        _ = freetype.c.FT_Set_Char_Size(newFont.ftFace, 0, pointSize * 64, 0, dpi);

        newFont.callbackData = .{
            .allocator = newFont.allocator,
            .face = newFont.ftFace,
        };
        const hbFace = harfbuzz.c.hb_face_create_for_tables(hbCallbackReferenceTables, @ptrCast(&newFont.callbackData), null);
        newFont.hbFont = harfbuzz.c.hb_font_create(hbFace);
        harfbuzz.c.hb_face_destroy(hbFace);

        const xScale: u64 = (@as(u64, @intCast(newFont.ftFace.*.size.*.metrics.x_scale)) * @as(u64, @intCast(newFont.ftFace.*.units_per_EM)) + (1 << 15)) >> 16;
        const yScale: u64 = (@as(u64, @intCast(newFont.ftFace.*.size.*.metrics.y_scale)) * @as(u64, @intCast(newFont.ftFace.*.units_per_EM)) + (1 << 15)) >> 16;
        harfbuzz.c.hb_font_set_scale(newFont.hbFont, @intCast(xScale), @intCast(yScale));

        return newFont;
    }

    pub fn free(self: *Font) void {
        harfbuzz.c.hb_font_destroy(self.hbFont);
        self.allocator.destroy(self);
    }

    pub fn shapeText(self: *Font, text: [:0]const u8, x: fp246, y: fp246, textureAtlas: *FontTextureAtlas, outputBuffer: *std.ArrayListUnmanaged(TextInstance)) !void {
        const buffer = harfbuzz.c.hb_buffer_create();
        defer harfbuzz.c.hb_buffer_destroy(buffer);
        harfbuzz.c.hb_buffer_add_utf8(buffer, text, -1, 0, -1);
        harfbuzz.c.hb_buffer_set_direction(buffer, harfbuzz.c.HB_DIRECTION_LTR);
        harfbuzz.c.hb_buffer_set_script(buffer, harfbuzz.c.HB_SCRIPT_LATIN);
        harfbuzz.c.hb_buffer_set_language(buffer, harfbuzz.c.hb_language_from_string("en", -1));

        harfbuzz.c.hb_shape(self.hbFont, buffer, 0, 0);
        var glyphCount: u32 = 0;
        const glyphInfo = harfbuzz.c.hb_buffer_get_glyph_infos(buffer, &glyphCount);
        const glyphPos = harfbuzz.c.hb_buffer_get_glyph_positions(buffer, &glyphCount);

        var textX = x;
        var textY = y;
        for (0..glyphCount) |i| {
            const glyphId = glyphInfo[i].codepoint;
            const glyphOffsetX = @as(f32, @floatFromInt(glyphPos[i].x_offset)) / 64;
            const glyphOffsetY = @as(f32, @floatFromInt(glyphPos[i].y_offset)) / 64;
            //std.log.debug("Glyph {d}: id = {d}, position = {d},{d}, offset = {d},{d}, advance = {d},{d}", .{ i, glyphId, xOffset, yOffset, xOffset, yOffset, xAdvance, yAdvance });

            const subX: u2 = @truncate(@abs(textX) / 16);
            const subY: u2 = @truncate(@abs(textY) / 16);
            const offsetIndex = @as(u4, subY) * 4 + subX;
            //std.log.debug("Glyph {d}: id = {d}, textX = {d} ({d}), textY = {d} ({d})", .{ i, glyphId, textX, subX, textY, subY });

            var delta: freetype.c.FT_Vector = .{ .x = @as(i32, subX) * 16, .y = @as(i32, subY) * 16 };
            freetype.c.FT_Set_Transform(self.ftFace, null, &delta);
            _ = freetype.c.FT_Load_Glyph(self.ftFace, glyphInfo[i].codepoint, freetype.c.FT_LOAD_RENDER | freetype.c.FT_LOAD_NO_HINTING);
            const glyph = self.ftFace.*.glyph.*;
            const slot = textureAtlas.getGlyph(self.id, glyphId, offsetIndex) orelse blk: {
                const slot = try textureAtlas.insertGlyph(self.allocator, self.id, glyphId, offsetIndex, @intCast(glyph.bitmap.width), @intCast(glyph.bitmap.rows), @intCast(glyph.bitmap_top), @intCast(glyph.bitmap_left));
                std.log.debug("Atlas: slot = {}", .{slot});
                std.log.debug("FT: advance = {d}, {d}", .{ glyph.advance.x, glyph.advance.y });
                //gl.texSubImage2D(.@"2d", 0, 20, 20, @abs(glyph.bitmap.pitch), glyph.bitmap.rows, .red, .unsigned_byte, glyph.bitmap.buffer);
                var source: usize = 0;
                var destination: usize = @as(u32, slot.position[1]) * FontTextureAtlas.TextureSize + @as(u32, slot.position[0]);
                for (0..glyph.bitmap.rows) |_| {
                    for (0..glyph.bitmap.width) |xpos| {
                        textureAtlas.textureBuffer[destination + xpos] = glyph.bitmap.buffer[source + xpos];
                    }
                    source += @abs(glyph.bitmap.pitch);
                    destination += FontTextureAtlas.TextureSize;
                }
                atlas.textureDirty = true;
                break :blk slot;
            };

            const fx = @as(f32, @floatFromInt(@divTrunc(textX, 64)));
            const fy = @as(f32, @floatFromInt(@divTrunc(textY, 64)));
            const instance = try outputBuffer.addOne(self.allocator);
            instance.* = .{
                .position = .{
                    fx + glyphOffsetX + @as(f32, @floatFromInt(slot.offset[0])),
                    fy + glyphOffsetY - @as(f32, @floatFromInt(slot.offset[1])),
                },
                .size = .{ @floatFromInt(slot.size[0]), @floatFromInt(slot.size[1]) },
                .texture = .{ @floatFromInt(slot.position[0]), @floatFromInt(slot.position[1]) },
                .color = .{ .r = 0, .g = 0, .b = 0, .a = 1 },
            };
            std.log.debug("Glyph instance: position = {d},{d} ({d},{d})", .{ instance.position[0], instance.position[1], textX, textY });
            textX += glyphPos[i].x_advance;
            textY += glyphPos[i].y_advance;
        }
    }
};

fn draw(windowId: platform.WindowId) void {
    if (platform.Window.fromId(windowId)) |window| {
        if (builtin.os.tag == .linux) {
            const g = @abs(@cos(gradient));
            const b = @abs(@sin(gradient));
            gl.clearColor(0.0, g, b, 1.0);
            gl.clear(.{ .color = true, .depth = true, .stencil = false });

            // UI instancing
            gl.enable(.blend);
            gl.blendFunc(.src_alpha, .one_minus_src_alpha);

            gl.useProgram(boxShaderProgram);
            gl.uniform2i(boxUniformWindowSize, @intCast(windowWidth), @intCast(windowHeight));

            boxVao.bind();
            boxInstanceVbo.bind(gl.BufferTarget.array_buffer);
            gl.bufferData(gl.BufferTarget.array_buffer, BoxInstance, boxInstanceBuffer[0..boxInstanceBuffer.len], gl.BufferUsage.dynamic_draw);
            //gl.activeTexture(gl.TextureUnit.texture_0);
            //uiWhiteTexture.bind(gl.TextureTarget.@"2d");
            gl.drawArraysInstanced(gl.PrimitiveType.triangles, 0, 6, boxInstanceBuffer.len);
            //uiBuffer.vertexBuffer.usedCount = 0;

            gl.useProgram(textShaderProgram);
            gl.uniform2i(textUniformWindowSize, @intCast(windowWidth), @intCast(windowHeight));

            if (atlas.textureDirty) {
                gl.textureImage2D(.@"2d", 0, .red, FontTextureAtlas.TextureSize, FontTextureAtlas.TextureSize, .red, .unsigned_byte, &atlas.textureBuffer);
                atlas.textureDirty = false;
            }
            textVao.bind();
            textInstanceVbo.bind(gl.BufferTarget.array_buffer);
            gl.bufferData(gl.BufferTarget.array_buffer, TextInstance, textInstanceBuffer.items[0..textInstanceBuffer.items.len], gl.BufferUsage.dynamic_draw);
            gl.uniform1i(textUniformTextureSampler0, 0);
            gl.activeTexture(gl.TextureUnit.texture_0);
            atlasTextureId.bind(gl.TextureTarget.@"2d");
            gl.drawArraysInstanced(gl.PrimitiveType.triangle_fan, 0, 4, textInstanceBuffer.items.len);

            gl.useProgram(ftShaderProgram);
            gl.uniform2i(ftUniformWindowSize, @intCast(windowWidth), @intCast(windowHeight));

            ftVao.bind();
            ftVbo.bind(gl.BufferTarget.array_buffer);
            gl.uniform1i(ftUniformTextureSampler0, 0);
            gl.activeTexture(gl.TextureUnit.texture_0);
            atlasTextureId.bind(gl.TextureTarget.@"2d");
            gl.drawArrays(gl.PrimitiveType.triangles, 0, 6);
        }

        window.swapBuffers();
    }
}
