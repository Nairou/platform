const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "example",
        .root_source_file = b.path("src/example.zig"),
        .target = target,
        .optimize = optimize,
    });

    if (b.lazyDependency("platform", .{
        .target = target,
        .optimize = optimize,
    })) |dep| {
        //exe.root_module.linkLibrary(dep.artifact("platform"));
        exe.root_module.addImport("platform", dep.module("platform"));
    }

    if (b.lazyDependency("zgl", .{
        .target = target,
        .optimize = optimize,
    })) |dep| {
        exe.root_module.addImport("zgl", dep.module("zgl"));
    }

    b.installArtifact(exe);
}
