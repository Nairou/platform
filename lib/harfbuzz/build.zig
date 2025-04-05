const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("harfbuzz", .{});

    const module = b.addModule("harfbuzz", .{
        .root_source_file = b.path("lib.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    module.addIncludePath(upstream.path("src"));

    const flags = .{
        "-fno-sanitize=undefined",
    };
    module.addCSourceFile(.{ .file = upstream.path("src/harfbuzz.cc"), .flags = &flags });

    if (target.result.os.tag == .linux) {
        module.addCMacro("HAVE_UNISTD_H", "1");
        module.addCMacro("HAVE_FCNTL_H", "1");
    }

    //lib.installHeadersDirectory(upstream.path("src"), "", .{});

    const lib = b.addLibrary(.{
        .name = "harfbuzz",
        .root_module = module,
    });

    b.installArtifact(lib);
    //module.linkLibrary(lib);
}
