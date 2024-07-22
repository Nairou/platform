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
    lib.addIncludePath(b.path("src/egl"));
    lib.addIncludePath(b.path("src/wayland"));
    lib.addIncludePath(b.path("src/x11"));
    lib.addCSourceFiles(.{
        .files = &protocol_sources,
    });
    lib.linkLibC();
    lib.linkSystemLibrary("wayland-client");
    lib.linkSystemLibrary("wayland-egl");
    lib.linkSystemLibrary("EGL");
    lib.linkSystemLibrary("xkbcommon");

    if (b.lazyDependency("zgl", .{
        .target = target,
        .optimize = optimize,
    })) |dep| {
        lib.root_module.addImport("zgl", dep.module("zgl"));
    }

    b.installArtifact(lib);

    const test_lib = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    //test_lib.linkLibrary(lib);
    test_lib.addIncludePath(b.path("src/egl"));
    test_lib.addIncludePath(b.path("src/wayland"));
    test_lib.addIncludePath(b.path("src/x11"));
    test_lib.addCSourceFiles(.{
        .files = &protocol_sources,
    });
    test_lib.linkLibC();
    test_lib.linkSystemLibrary("wayland-client");
    test_lib.linkSystemLibrary("wayland-egl");
    test_lib.linkSystemLibrary("EGL");
    test_lib.linkSystemLibrary("xkbcommon");

    if (b.lazyDependency("zgl", .{
        .target = target,
        .optimize = optimize,
    })) |dep| {
        test_lib.root_module.addImport("zgl", dep.module("zgl"));
    }

    const run_lib_unit_tests = b.addRunArtifact(test_lib);
    const install_lib_unit_tests = b.addInstallArtifact(test_lib, .{});

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    const testbin_step = b.step("test-bin", "Build unit tests into separate binary");
    testbin_step.dependOn(&install_lib_unit_tests.step);
}

const protocol_sources = [_][]const u8{
    "src/wayland/wayland-protocol.c",
    "src/wayland/xdg-shell-protocol.c",
};
