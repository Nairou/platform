const std = @import("std");
const builtin = @import("builtin");
const harfbuzz = @import("harfbuzz");
const freetype = @import("freetype");
const platform = @import("platform");
const gl = @import("zgl");

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
var ftTextureId: gl.Texture = undefined;
var ftTextureBuffer: [1024 * 1024]u8 = @splat(0);
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

fn hbCallbackGetHExtents(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, extents: [*c]harfbuzz.c.hb_font_extents_t, user_data: ?*anyopaque) callconv(.C) i32 {
    _ = font;
    _ = font_data;
    _ = extents;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: get_h_extents", .{});
    return 0;
}
fn hbCallbackGetVExtents(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, extents: [*c]harfbuzz.c.hb_font_extents_t, user_data: ?*anyopaque) callconv(.C) i32 {
    _ = font;
    _ = font_data;
    _ = extents;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: get_v_extents", .{});
    return 0;
}
fn hbCallbackGetNominalGlyph(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, unicode: harfbuzz.c.hb_codepoint_t, glyph: [*c]harfbuzz.c.hb_codepoint_t, user_data: ?*anyopaque) callconv(.C) i32 {
    _ = font;
    _ = font_data;
    _ = unicode;
    _ = glyph;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: get_nominal_glyph", .{});
    return 0;
}
fn hbCallbackGetNominalGlyphs(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, count: u32, first_unicode: [*c]const harfbuzz.c.hb_codepoint_t, unicode_stride: u32, first_glyph: [*c]harfbuzz.c.hb_codepoint_t, glyph_stride: u32, user_data: ?*anyopaque) callconv(.C) u32 {
    _ = font;
    _ = font_data;
    _ = count;
    _ = first_unicode;
    _ = unicode_stride;
    _ = first_glyph;
    _ = glyph_stride;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: get_nominal_glyphs", .{});
    return 0;
}
fn hbCallbackGetVariationGlyph(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, unicode: harfbuzz.c.hb_codepoint_t, variation_selector: harfbuzz.c.hb_codepoint_t, glyph: [*c]harfbuzz.c.hb_codepoint_t, user_data: ?*anyopaque) callconv(.C) i32 {
    _ = font;
    _ = font_data;
    _ = unicode;
    _ = variation_selector;
    _ = glyph;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: get_variation_glyph", .{});
    return 0;
}
fn hbCallbackGetGlyphHAdvance(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, glyph: harfbuzz.c.hb_codepoint_t, user_data: ?*anyopaque) callconv(.C) harfbuzz.c.hb_position_t {
    _ = font;
    _ = font_data;
    _ = glyph;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: get_glyph_h_advance", .{});
    return 0;
}
fn hbCallbackGetGlyphVAdvance(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, glyph: harfbuzz.c.hb_codepoint_t, user_data: ?*anyopaque) callconv(.C) harfbuzz.c.hb_position_t {
    _ = font;
    _ = font_data;
    _ = glyph;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: get_glyph_v_advance", .{});
    return 0;
}
fn hbCallbackGetGlyphHAdvances(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, count: u32, first_glyph: [*c]const harfbuzz.c.hb_codepoint_t, glyph_stride: u32, first_advance: [*c]harfbuzz.c.hb_position_t, advance_stride: u32, user_data: ?*anyopaque) callconv(.C) void {
    _ = font;
    _ = font_data;
    _ = count;
    _ = first_glyph;
    _ = glyph_stride;
    _ = first_advance;
    _ = advance_stride;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: get_glyph_h_advances", .{});
}
fn hbCallbackGetGlyphVAdvances(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, count: u32, first_glyph: [*c]const harfbuzz.c.hb_codepoint_t, glyph_stride: u32, first_advance: [*c]harfbuzz.c.hb_position_t, advance_stride: u32, user_data: ?*anyopaque) callconv(.C) void {
    _ = font;
    _ = font_data;
    _ = count;
    _ = first_glyph;
    _ = glyph_stride;
    _ = first_advance;
    _ = advance_stride;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: get_glyph_v_advances", .{});
}
fn hbCallbackGetGlyphHOrigin(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, glyph: harfbuzz.c.hb_codepoint_t, x: [*c]harfbuzz.c.hb_position_t, y: [*c]harfbuzz.c.hb_position_t, user_data: ?*anyopaque) callconv(.C) i32 {
    _ = font;
    _ = font_data;
    _ = glyph;
    _ = x;
    _ = y;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: get_glyph_h_origin", .{});
    return 0;
}
fn hbCallbackGetGlyphVOrigin(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, glyph: harfbuzz.c.hb_codepoint_t, x: [*c]harfbuzz.c.hb_position_t, y: [*c]harfbuzz.c.hb_position_t, user_data: ?*anyopaque) callconv(.C) i32 {
    _ = font;
    _ = font_data;
    _ = glyph;
    _ = x;
    _ = y;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: get_glyph_v_origin", .{});
    return 0;
}
fn hbCallbackGetGlyphHKerning(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, left_glyph: harfbuzz.c.hb_codepoint_t, right_glyph: harfbuzz.c.hb_codepoint_t, user_data: ?*anyopaque) callconv(.C) harfbuzz.c.hb_position_t {
    _ = font;
    _ = font_data;
    _ = left_glyph;
    _ = right_glyph;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: get_glyph_h_kerning", .{});
    return 0;
}
fn hbCallbackGetGlyphExtents(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, glyph: harfbuzz.c.hb_codepoint_t, extents: [*c]harfbuzz.c.hb_glyph_extents_t, user_data: ?*anyopaque) callconv(.C) i32 {
    _ = font;
    _ = font_data;
    _ = glyph;
    _ = extents;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: get_glyph_extents", .{});
    return 0;
}
fn hbCallbackGetGlyphContourPoint(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, glyph: harfbuzz.c.hb_codepoint_t, point_index: u32, x: [*c]harfbuzz.c.hb_position_t, y: [*c]harfbuzz.c.hb_position_t, user_data: ?*anyopaque) callconv(.C) i32 {
    _ = font;
    _ = font_data;
    _ = glyph;
    _ = point_index;
    _ = x;
    _ = y;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: get_glyph_contour_point", .{});
    return 0;
}
fn hbCallbackGetGlyphName(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, glyph: harfbuzz.c.hb_codepoint_t, name: [*c]u8, size: u32, user_data: ?*anyopaque) callconv(.C) i32 {
    _ = font;
    _ = font_data;
    _ = glyph;
    _ = name;
    _ = size;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: get_glyph_name", .{});
    return 0;
}
fn hbCallbackGetGlyphFromName(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, name: [*c]const u8, len: i32, glyph: [*c]harfbuzz.c.hb_codepoint_t, user_data: ?*anyopaque) callconv(.C) i32 {
    _ = font;
    _ = font_data;
    _ = name;
    _ = len;
    _ = glyph;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: get_glyph_from_name", .{});
    return 0;
}
fn hbCallbackDrawGlyph(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, glyph: harfbuzz.c.hb_codepoint_t, dfuncs: ?*harfbuzz.c.hb_draw_funcs_t, draw_data: ?*anyopaque, user_data: ?*anyopaque) callconv(.C) void {
    _ = font;
    _ = font_data;
    _ = glyph;
    _ = dfuncs;
    _ = draw_data;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: draw_glyph", .{});
}
fn hbCallbackPaintGlyph(font: ?*harfbuzz.c.hb_font_t, font_data: ?*anyopaque, glyph: harfbuzz.c.hb_codepoint_t, pfuncs: ?*harfbuzz.c.hb_paint_funcs_t, paint_data: ?*anyopaque, palette_index: u32, foreground: harfbuzz.c.hb_color_t, user_data: ?*anyopaque) callconv(.C) void {
    _ = font;
    _ = font_data;
    _ = glyph;
    _ = pfuncs;
    _ = paint_data;
    _ = palette_index;
    _ = foreground;
    _ = user_data;
    std.log.debug("Harfbuzz CALLBACK: paint_glyph", .{});
}
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

    var atlasAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer atlasAllocator.deinit();

    var textAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer textAllocator.deinit();

    var ftLib: freetype.c.FT_Library = undefined;
    _ = freetype.c.FT_Init_FreeType(&ftLib);
    var ftFace: freetype.c.FT_Face = undefined;
    _ = freetype.c.FT_New_Face(ftLib, "Roboto-Medium.ttf", 0, &ftFace);
    std.log.debug("FT_Face num_glyphs = {d}", .{ftFace.*.num_glyphs});
    _ = freetype.c.FT_Set_Char_Size(ftFace, 0, 48 * 64, 0, 72);

    var callbackData: CallbackFaceAllocator = .{
        .allocator = std.heap.page_allocator,
        .face = ftFace,
    };
    const face = harfbuzz.c.hb_face_create_for_tables(hbCallbackReferenceTables, @ptrCast(&callbackData), null);
    defer harfbuzz.c.hb_face_destroy(face);
    const font = harfbuzz.c.hb_font_create(face);
    defer harfbuzz.c.hb_font_destroy(font);

    //const hbCallbacks = harfbuzz.c.hb_font_funcs_create();
    //harfbuzz.c.hb_font_funcs_set_font_h_extents_func(hbCallbacks, hbCallbackGetHExtents, null, null);
    //harfbuzz.c.hb_font_funcs_set_font_v_extents_func(hbCallbacks, hbCallbackGetVExtents, null, null);
    //harfbuzz.c.hb_font_funcs_set_nominal_glyph_func(hbCallbacks, hbCallbackGetNominalGlyph, null, null);
    //harfbuzz.c.hb_font_funcs_set_nominal_glyphs_func(hbCallbacks, hbCallbackGetNominalGlyphs, null, null);
    //harfbuzz.c.hb_font_funcs_set_variation_glyph_func(hbCallbacks, hbCallbackGetVariationGlyph, null, null);
    //harfbuzz.c.hb_font_funcs_set_glyph_h_advance_func(hbCallbacks, hbCallbackGetGlyphHAdvance, null, null);
    //harfbuzz.c.hb_font_funcs_set_glyph_v_advance_func(hbCallbacks, hbCallbackGetGlyphVAdvance, null, null);
    //harfbuzz.c.hb_font_funcs_set_glyph_h_advances_func(hbCallbacks, hbCallbackGetGlyphHAdvances, null, null);
    //harfbuzz.c.hb_font_funcs_set_glyph_v_advances_func(hbCallbacks, hbCallbackGetGlyphVAdvances, null, null);
    //harfbuzz.c.hb_font_funcs_set_glyph_h_origin_func(hbCallbacks, hbCallbackGetGlyphHOrigin, null, null);
    //harfbuzz.c.hb_font_funcs_set_glyph_v_origin_func(hbCallbacks, hbCallbackGetGlyphVOrigin, null, null);
    //harfbuzz.c.hb_font_funcs_set_glyph_h_kerning_func(hbCallbacks, hbCallbackGetGlyphHKerning, null, null);
    //harfbuzz.c.hb_font_funcs_set_glyph_extents_func(hbCallbacks, hbCallbackGetGlyphExtents, null, null);
    //harfbuzz.c.hb_font_funcs_set_glyph_contour_point_func(hbCallbacks, hbCallbackGetGlyphContourPoint, null, null);
    //harfbuzz.c.hb_font_funcs_set_glyph_name_func(hbCallbacks, hbCallbackGetGlyphName, null, null);
    //harfbuzz.c.hb_font_funcs_set_glyph_from_name_func(hbCallbacks, hbCallbackGetGlyphFromName, null, null);
    //harfbuzz.c.hb_font_funcs_set_draw_glyph_func(hbCallbacks, hbCallbackDrawGlyph, null, null);
    //harfbuzz.c.hb_font_funcs_set_paint_glyph_func(hbCallbacks, hbCallbackPaintGlyph, null, null);
    //harfbuzz.c.hb_font_funcs_make_immutable(hbCallbacks);

    //const subfont = harfbuzz.c.hb_font_create_sub_font(font);
    //harfbuzz.c.hb_font_set_funcs(subfont, hbCallbacks, ftFace, null);
    //harfbuzz.c.hb_font_funcs_destroy(hbCallbacks);

    const xScale: u64 = (@as(u64, @intCast(ftFace.*.size.*.metrics.x_scale)) * @as(u64, @intCast(ftFace.*.units_per_EM)) + (1 << 15)) >> 16;
    const yScale: u64 = (@as(u64, @intCast(ftFace.*.size.*.metrics.y_scale)) * @as(u64, @intCast(ftFace.*.units_per_EM)) + (1 << 15)) >> 16;
    std.log.debug("FT: scale = {d}, {d}, unitsPerEM = {d}", .{ ftFace.*.size.*.metrics.x_scale, ftFace.*.size.*.metrics.y_scale, ftFace.*.units_per_EM });
    std.log.debug("Scale: {d}, {d}", .{ xScale, yScale });
    harfbuzz.c.hb_font_set_scale(font, @intCast(xScale), @intCast(yScale));

    const buffer = harfbuzz.c.hb_buffer_create();
    defer harfbuzz.c.hb_buffer_destroy(buffer);
    harfbuzz.c.hb_buffer_add_utf8(buffer, "Hello, World! Totally awesome...", -1, 0, -1);
    harfbuzz.c.hb_buffer_set_direction(buffer, harfbuzz.c.HB_DIRECTION_LTR);
    harfbuzz.c.hb_buffer_set_script(buffer, harfbuzz.c.HB_SCRIPT_LATIN);
    harfbuzz.c.hb_buffer_set_language(buffer, harfbuzz.c.hb_language_from_string("en", -1));

    harfbuzz.c.hb_shape(font, buffer, 0, 0);
    var glyphCount: u32 = 0;
    const glyphInfo = harfbuzz.c.hb_buffer_get_glyph_infos(buffer, &glyphCount);
    const glyphPos = harfbuzz.c.hb_buffer_get_glyph_positions(buffer, &glyphCount);

    const tempGlyphCount = harfbuzz.c.hb_face_get_glyph_count(face);
    std.log.debug("glyph_count result: {d}", .{tempGlyphCount});

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

        ftTextureId = gl.genTexture();
        ftTextureId.bind(.@"2d");
        gl.texParameter(.@"2d", .min_filter, gl.TextureParameterType(.min_filter).nearest);
        gl.texParameter(.@"2d", .mag_filter, gl.TextureParameterType(.mag_filter).nearest);
        gl.texParameter(.@"2d", .wrap_r, gl.TextureParameterType(.wrap_r).repeat);
        gl.texParameter(.@"2d", .wrap_s, gl.TextureParameterType(.wrap_s).repeat);
        gl.texParameter(.@"2d", .wrap_t, gl.TextureParameterType(.wrap_t).repeat);

        const textureDim = 1024;

        std.log.debug("Glyph count: {d}", .{glyphCount});
        var textX: f32 = 100;
        var textY: f32 = 100;
        for (0..glyphCount) |i| {
            const glyphId = glyphInfo[i].codepoint;

            _ = freetype.c.FT_Load_Glyph(ftFace, glyphInfo[i].codepoint, freetype.c.FT_LOAD_RENDER | freetype.c.FT_LOAD_NO_HINTING);
            const glyph = ftFace.*.glyph.*;
            const slot = atlas.getGlyph(123, glyphId) orelse blk: {
                const slot = try atlas.insertGlyph(atlasAllocator.allocator(), 123, glyphId, @intCast(glyph.bitmap.width), @intCast(glyph.bitmap.rows), @intCast(glyph.bitmap_top), @intCast(glyph.bitmap_left));
                std.log.debug("Atlas: slot = {}", .{slot});
                std.log.debug("FT: advance = {d}, {d}", .{ glyph.advance.x, glyph.advance.y });
                //gl.texSubImage2D(.@"2d", 0, 20, 20, @abs(glyph.bitmap.pitch), glyph.bitmap.rows, .red, .unsigned_byte, glyph.bitmap.buffer);
                var source: usize = 0;
                var destination: usize = @as(u32, slot.position[1]) * textureDim + @as(u32, slot.position[0]);
                for (0..glyph.bitmap.rows) |_| {
                    for (0..glyph.bitmap.width) |x| {
                        ftTextureBuffer[destination + x] = glyph.bitmap.buffer[source + x];
                    }
                    source += @abs(glyph.bitmap.pitch);
                    destination += textureDim;
                }
                break :blk slot;
            };

            const xOffset = @as(f32, @floatFromInt(glyphPos[i].x_offset)) / 64;
            const yOffset = @as(f32, @floatFromInt(glyphPos[i].y_offset)) / 64;
            const xAdvance = @as(f32, @floatFromInt(glyphPos[i].x_advance)) / 64;
            const yAdvance = @as(f32, @floatFromInt(glyphPos[i].y_advance)) / 64;
            //const xBearing = @as(f32, @floatFromInt(glyph.metrics.horiBearingX)) / 64;
            //const yBearing = @as(f32, @floatFromInt(glyph.metrics.horiBearingY)) / 64;
            std.log.debug("Glyph {d}: id = {d}, position = {d},{d}, offset = {d},{d}, advance = {d},{d}", .{ i, glyphId, xOffset, yOffset, xOffset, yOffset, xAdvance, yAdvance });

            const instance = try textInstanceBuffer.addOne(textAllocator.allocator());
            instance.* = .{
                .position = .{ textX + xOffset + @as(f32, @floatFromInt(slot.offset[0])), textY + yOffset - @as(f32, @floatFromInt(slot.offset[1])) },
                .size = .{ @floatFromInt(slot.size[0]), @floatFromInt(slot.size[1]) },
                .texture = .{ @floatFromInt(slot.position[0]), @floatFromInt(slot.position[1]) },
                .color = .{ .r = 1, .g = 1, .b = 1, .a = 1 },
            };
            std.log.debug("Glyph instance: position = {d},{d} ({d},{d})", .{ instance.position[0], instance.position[1], textX, textY });
            textX += xAdvance;
            textY += yAdvance;
        }
        gl.textureImage2D(.@"2d", 0, .red, textureDim, textureDim, .red, .unsigned_byte, &ftTextureBuffer);
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
        textUniformTextureSampler0 = ftShaderProgram.uniformLocation("TextureSampler");
    }

    draw(window.id);

    var running = true;
    while (running) {
        while (platform.readNextEvent(true)) |event| {
            switch (event) {
                .window_refresh => |window_refresh| {
                    gradient += 0.001;
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

    const Size = 1024;

    pub const Key = struct {
        font: u32,
        glyph: u32,
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

    pub fn getGlyph(self: *FontTextureAtlas, font: u32, glyph: u32) ?Slot {
        const key: Key = .{ .font = font, .glyph = glyph };
        return self.glyphMap.get(key);
    }

    pub fn insertGlyph(self: *FontTextureAtlas, allocator: std.mem.Allocator, font: u32, glyph: u32, width: u16, height: u16, top: i16, left: i16) !Slot {
        std.log.debug("Insert glyph {d}, width = {d}, height = {d}", .{ glyph, width, height });
        const slotWidth = width + 1;
        const slotHeight = ((height + 4) / 5) * 5 + 1;
        std.debug.assert(slotWidth < Size);
        std.debug.assert(slotHeight < Size);
        const key: Key = .{ .font = font, .glyph = glyph };
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
                break Slot{ .position = .{ Size - shelf.remaining, shelf.offset }, .size = .{ width, height }, .offset = .{ left, top } };
            }
            nextOffset += shelf.height;
        } else blk: {
            std.log.debug("Glyph height {d} fit no shelves, adding new shelf, offset = {d}", .{ height, nextOffset });
            std.debug.assert(nextOffset <= Size);
            if (Size - nextOffset < slotHeight) {
                return error.AtlasIsFull;
            }

            const shelf = try self.shelves.addOne(allocator);
            shelf.* = .{
                .offset = nextOffset,
                .height = slotHeight,
                .remaining = Size - slotWidth,
            };
            break :blk Slot{ .position = .{ 0, shelf.offset }, .size = .{ width, height }, .offset = .{ left, top } };
        };

        std.log.debug("Added to atlas: font = {d}, glyph = {d}, data = {}", .{ font, glyph, slot });

        try self.glyphMap.put(allocator, key, slot);
        return slot;
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

            textVao.bind();
            textInstanceVbo.bind(gl.BufferTarget.array_buffer);
            gl.bufferData(gl.BufferTarget.array_buffer, TextInstance, textInstanceBuffer.items[0..textInstanceBuffer.items.len], gl.BufferUsage.dynamic_draw);
            gl.uniform1i(ftUniformTextureSampler0, 0);
            gl.activeTexture(gl.TextureUnit.texture_0);
            ftTextureId.bind(gl.TextureTarget.@"2d");
            gl.drawArraysInstanced(gl.PrimitiveType.triangle_fan, 0, 4, textInstanceBuffer.items.len);

            gl.useProgram(ftShaderProgram);
            gl.uniform2i(ftUniformWindowSize, @intCast(windowWidth), @intCast(windowHeight));

            ftVao.bind();
            ftVbo.bind(gl.BufferTarget.array_buffer);
            gl.uniform1i(ftUniformTextureSampler0, 0);
            gl.activeTexture(gl.TextureUnit.texture_0);
            ftTextureId.bind(gl.TextureTarget.@"2d");
            gl.drawArrays(gl.PrimitiveType.triangles, 0, 6);
        }

        window.swapBuffers();
    }
}
