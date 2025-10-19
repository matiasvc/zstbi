const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const zstbi = b.addModule("root", .{
        .root_source_file = b.path("src/zstbi.zig"),
    });

    zstbi.addIncludePath(b.path("libs/stbi"));

    const base_flags = &[_][]const u8{
        "-std=c99",
        "-fno-sanitize=undefined",
        "-O3",
    };

    const flags: []const []const u8 = switch (target.result.cpu.arch) {
        .x86_64 => base_flags ++ &[_][]const u8{
            "-march=x86-64-v2",
            "-msse2",
            "-DSTBI_SSE2",
        },
        .aarch64 => base_flags ++ &[_][]const u8{
            "-march=armv8-a",
            "-DSTBI_NEON",
        },
        else => base_flags,
    };

    zstbi.addCSourceFile(.{
        .file = b.path("src/zstbi.c"),
        .flags = flags,
    });

    if (target.result.os.tag == .emscripten) {
        zstbi.addIncludePath(.{
            .cwd_relative = b.pathJoin(&.{ b.sysroot.?, "/include" }),
        });
    } else {
        zstbi.link_libc = true;
    }

    const test_step = b.step("test", "Run zstbi tests");

    const tests = b.addTest(.{
        .name = "zstbi-tests",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/zstbi.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    tests.root_module.addImport("zstbi", zstbi);
    b.installArtifact(tests);

    test_step.dependOn(&b.addRunArtifact(tests).step);
}
