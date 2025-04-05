const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const platform = b.dependency("platform", .{
        .target = target,
        .optimize = optimize,
    });
    const freetype = b.dependency("freetype", .{
        .target = target,
        .optimize = optimize,
    });
    const harfbuzz = b.dependency("harfbuzz", .{
        .target = target,
        .optimize = optimize,
    });
    const zgl = b.dependency("zgl", .{
        .target = target,
        .optimize = optimize,
    });

    const example = b.createModule(.{
        .root_source_file = b.path("src/example.zig"),
        .target = target,
        .optimize = optimize,
    });
    example.addImport("platform", platform.module("platform"));
    example.addImport("freetype", freetype.module("freetype"));
    example.addImport("harfbuzz", harfbuzz.module("harfbuzz"));
    example.addImport("zgl", zgl.module("zgl"));

    const exe = b.addExecutable(.{
        .name = "example",
        .root_module = example,
    });

    b.installArtifact(exe);
}
