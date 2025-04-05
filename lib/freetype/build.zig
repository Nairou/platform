const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("freetype", .{});

    const module = b.addModule("freetype", .{
        .root_source_file = b.path("lib.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    module.addIncludePath(upstream.path("include"));

    const flags = .{
        "-fno-sanitize=undefined",
    };

    module.addCMacro("FT2_BUILD_LIBRARY", "1");
    switch (target.result.os.tag) {
        .linux => {
            module.addCMacro("HAVE_UNISTD_H", "1");
            module.addCMacro("HAVE_FCNTL_H", "1");
            module.addCSourceFile(.{ .file = upstream.path("builds/unix/ftsystem.c"), .flags = &flags });
            module.addCSourceFile(.{ .file = upstream.path("src/base/ftdebug.c"), .flags = &flags });
        },
        .windows => {
            module.addCSourceFile(.{ .file = upstream.path("builds/windows/ftsystem.c"), .flags = &flags });
            module.addCSourceFile(.{ .file = upstream.path("builds/windows/ftdebug.c"), .flags = &flags });
        },
        .macos => {
            module.addCSourceFile(.{ .file = upstream.path("src/base/ftsystem.c"), .flags = &flags });
            module.addCSourceFile(.{ .file = upstream.path("src/base/ftdebug.c"), .flags = &flags });
            module.addCSourceFile(.{ .file = upstream.path("src/base/ftmac.c"), .flags = &flags });
        },
        else => {},
    }

    module.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = sources,
        .flags = &flags,
    });

    const lib = b.addLibrary(.{
        .name = "freetype",
        .root_module = module,
    });
    //lib.installHeadersDirectory(upstream.path("include"), "", .{});

    b.installArtifact(lib);
    //module.linkLibrary(lib);
}

const sources = &.{
    "src/autofit/autofit.c",
    "src/base/ftbase.c",
    "src/base/ftbbox.c",
    "src/base/ftbdf.c",
    "src/base/ftbitmap.c",
    "src/base/ftcid.c",
    "src/base/ftfstype.c",
    "src/base/ftgasp.c",
    "src/base/ftglyph.c",
    "src/base/ftgxval.c",
    "src/base/ftinit.c",
    "src/base/ftmm.c",
    "src/base/ftotval.c",
    "src/base/ftpatent.c",
    "src/base/ftpfr.c",
    "src/base/ftstroke.c",
    "src/base/ftsynth.c",
    "src/base/fttype1.c",
    "src/base/ftwinfnt.c",
    "src/bdf/bdf.c",
    "src/bzip2/ftbzip2.c",
    "src/cache/ftcache.c",
    "src/cff/cff.c",
    "src/cid/type1cid.c",
    "src/gzip/ftgzip.c",
    "src/lzw/ftlzw.c",
    "src/pcf/pcf.c",
    "src/pfr/pfr.c",
    "src/psaux/psaux.c",
    "src/pshinter/pshinter.c",
    "src/psnames/psnames.c",
    "src/raster/raster.c",
    "src/sdf/sdf.c",
    "src/sfnt/sfnt.c",
    "src/smooth/smooth.c",
    "src/svg/svg.c",
    "src/truetype/truetype.c",
    "src/type1/type1.c",
    "src/type42/type42.c",
    "src/winfonts/winfnt.c",
};
