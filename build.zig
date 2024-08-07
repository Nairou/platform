const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("platform", .{
        .root_source_file = b.path("src/lib.zig"),
        .link_libc = true,
    });
    module.addIncludePath(b.path("src/egl"));
    module.addIncludePath(b.path("src/wayland"));
    module.addIncludePath(b.path("src/x11"));

    // Library
    const lib = b.addStaticLibrary(.{
        .name = "platform",
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib.addIncludePath(b.path("src/egl"));
    lib.addIncludePath(b.path("src/wayland"));
    lib.addIncludePath(b.path("src/x11"));
    lib.addCSourceFiles(.{
        .files = &protocol_sources,
    });
    lib.linkSystemLibrary("wayland-client");
    lib.linkSystemLibrary("wayland-egl");
    lib.linkSystemLibrary("EGL");
    lib.linkSystemLibrary("xkbcommon");

    b.installArtifact(lib);
    module.linkLibrary(lib);

    // Tests
    {
        const test_lib = b.addTest(.{
            .root_source_file = b.path("src/lib.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        test_lib.linkLibrary(lib);
        test_lib.addIncludePath(b.path("src/egl"));
        test_lib.addIncludePath(b.path("src/wayland"));
        test_lib.addIncludePath(b.path("src/x11"));

        const test_step = b.step("test", "Run unit tests");
        const test_step_run = b.addRunArtifact(test_lib);
        test_step_run.has_side_effects = true;
        test_step.dependOn(&test_step_run.step);

        const testbin_step = b.step("test-bin", "Build unit tests into separate binary");
        const testbin_step_run = b.addInstallArtifact(test_lib, .{});
        testbin_step.dependOn(&testbin_step_run.step);
    }
}

const protocol_sources = [_][]const u8{
    "src/wayland/wayland-protocol.c",
    "src/wayland/xdg-shell-protocol.c",
};
