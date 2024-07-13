const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "platform",
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib.addIncludePath(b.path("src/wayland"));
    lib.addCSourceFiles(.{
        .files = &protocol_sources,
    });
    lib.linkLibC();
    lib.linkSystemLibrary("wayland-client");

    b.installArtifact(lib);

    const lib_tests = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_tests.addIncludePath(b.path("src/wayland"));
    lib_tests.addCSourceFiles(.{
        .files = &protocol_sources,
    });
    lib_tests.linkLibC();
    lib_tests.linkSystemLibrary("wayland-client");

    const run_lib_unit_tests = b.addRunArtifact(lib_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}

const protocol_sources = [_][]const u8{
    "src/wayland/wayland-protocol.c",
    "src/wayland/xdg-shell-protocol.c",
};
