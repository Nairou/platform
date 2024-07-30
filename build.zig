const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("platform", .{
        .root_source_file = b.path("src/lib.zig"),
    });

    // Library
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
    module.linkLibrary(lib);

    // Tests
    {
        const test_lib = b.addTest(.{
            .root_source_file = b.path("src/lib.zig"),
            .target = target,
            .optimize = optimize,
        });
        test_lib.root_module.addImport("platform", module);
        //test_lib.addIncludePath(b.path("src/egl"));
        //test_lib.addIncludePath(b.path("src/wayland"));
        //test_lib.addIncludePath(b.path("src/x11"));
        //test_lib.addCSourceFiles(.{
        //    .files = &protocol_sources,
        //});
        //test_lib.linkLibC();
        //test_lib.linkSystemLibrary("wayland-client");
        //test_lib.linkSystemLibrary("wayland-egl");
        //test_lib.linkSystemLibrary("EGL");
        //test_lib.linkSystemLibrary("xkbcommon");

        const test_step = b.step("test", "Run unit tests");
        const test_step_run = b.addRunArtifact(test_lib);
        test_step.dependOn(&test_step_run.step);

        const testbin_step = b.step("test-bin", "Build unit tests into separate binary");
        const testbin_step_run = b.addInstallArtifact(test_lib, .{});
        testbin_step.dependOn(&testbin_step_run.step);
    }

    // Example
    {
        const example = b.addExecutable(.{
            .name = "example",
            .root_source_file = b.path("src/example.zig"),
            .target = target,
            .optimize = optimize,
        });
        example.root_module.addImport("platform", module);

        const example_step = b.step("example", "Build example");
        const example_step_run = b.addInstallArtifact(example, .{});
        example_step.dependOn(&example_step_run.step);
    }
}

const protocol_sources = [_][]const u8{
    "src/wayland/wayland-protocol.c",
    "src/wayland/xdg-shell-protocol.c",
};
