const std = @import("std");
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;

allocator: *std.mem.Allocator,
base_path: []const u8,

const Self = @This();
const name = "z";
const version = std.build.Version{
    .major = 1,
    .minor = 2,
    .patch = 11,
};

const LibraryType = enum {
    static,
    shared,
};

pub fn init(allocator: *std.mem.Allocator, base_path: []const u8) Self {
    return Self{
        .allocator = allocator,
        .base_path = base_path,
    };
}

pub fn addLibrary(
    self: Self,
    b: *Builder,
    lib_type: LibraryType,
    target: std.build.Target,
    mode: std.builtin.Mode,
) !*LibExeObjStep {
    const lib = switch (lib_type) {
        .static => b.addStaticLibrary(name, null),
        .shared => b.addSharedLibrary(name, null, .{ .versioned = version }),
    };

    for (srcs) |src| {
        lib.addCSourceFile(
            try std.fs.path.join(self.allocator, &[_][]const u8{ self.base_path, src }),
            &[_][]const u8{},
        );
    }

    lib.setTarget(target);
    lib.setBuildMode(mode);
    const install_header = b.addInstallFile(
        try std.fs.path.join(self.allocator, &[_][]const u8{ self.base_path, "zlib.h" }),
        try std.fs.path.join(self.allocator, &[_][]const u8{ "include", "zlib.h" }),
    );
    lib.linkLibC();
    lib.step.dependOn(&install_header.step);
    return lib;
}

const srcs = [_][]const u8{
    "adler32.c",
    "compress.c",
    "crc32.c",
    "deflate.c",
    "gzclose.c",
    "gzlib.c",
    "gzread.c",
    "gzwrite.c",
    "inflate.c",
    "infback.c",
    "inftrees.c",
    "inffast.c",
    "trees.c",
    "uncompr.c",
    "zutil.c",
};
