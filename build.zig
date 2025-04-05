const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("platform", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const lib = b.addLibrary(.{
        .name = "platform",
        .root_module = module,
    });

    switch (target.result.os.tag) {
        .linux => {
            const includes = [_][]const u8{
                "src/egl",
                "src/wayland",
                "src/x11",
            };
            for (includes) |path| {
                module.addIncludePath(b.path(path));
            }
            module.addCSourceFiles(.{
                .files = &protocol_sources,
            });
            module.linkSystemLibrary("wayland-client", .{});
            module.linkSystemLibrary("wayland-egl", .{});
            module.linkSystemLibrary("EGL", .{});
            module.linkSystemLibrary("xkbcommon", .{});
        },
        .windows => {
            //lib.linkSystemLibrary("gdi32");
            //lib.linkSystemLibrary("user32");
            //lib.linkSystemLibrary("kernel32");
        },
        else => {},
    }

    b.installArtifact(lib);

    // Tests
    {
        const test_lib = b.addTest(.{
            .root_source_file = b.path("src/lib.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        test_lib.linkLibrary(lib);
        switch (target.result.os.tag) {
            .linux => {
                test_lib.addIncludePath(b.path("src/egl"));
                test_lib.addIncludePath(b.path("src/wayland"));
                test_lib.addIncludePath(b.path("src/x11"));
            },
            else => {},
        }

        const test_step = b.step("test", "Run unit tests");
        const test_step_run = b.addRunArtifact(test_lib);
        test_step_run.has_side_effects = true;
        test_step.dependOn(&test_step_run.step);
    }
}

const protocol_sources = [_][]const u8{
    "src/wayland/wayland-protocol.c",
    "src/wayland/xdg-shell-protocol.c",
};
