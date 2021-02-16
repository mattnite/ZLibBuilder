const std = @import("std");
const download = @import("download");
usingnamespace std.build;

const Self = @This();
const name = "z";

pub const version = std.build.Version{
    .major = 1,
    .minor = 2,
    .patch = 11,
};

pub const LinkType = enum {
    system,
    static,
    shared,
};

config: ?struct {
    arena: std.heap.ArenaAllocator,
    lib: *LibExeObjStep,
    include_dir: []const u8,
},

pub fn init(
    b: *Builder,
    target: Target,
    mode: std.builtin.Mode,
    link_type: LinkType,
) !Self {
    return if (link_type == .system)
        Self{ .config = null }
    else blk: {
        var arena = std.heap.ArenaAllocator.init(b.allocator);
        errdefer arena.deinit();

        const allocator = &arena.allocator;
        const base_path = try download.tar.gz(
            allocator,
            b.cache_root,
            "https://zlib.net/zlib-1.2.11.tar.gz",
            .{
                .name = "zlib-1.2.11",
                .sha256 = "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1",
            },
        );

        const lib = if (link_type == .static)
            b.addStaticLibrary(name, null)
        else
            b.addSharedLibrary(name, null, .{ .versioned = version });

        for (srcs) |src| {
            lib.addCSourceFile(try std.fs.path.join(allocator, &[_][]const u8{
                base_path, src,
            }), &[_][]const u8{});
        }

        lib.addIncludeDir(base_path);
        lib.setTarget(target);
        lib.setBuildMode(mode);
        lib.linkLibC();
        break :blk Self{
            .config = .{
                .arena = arena,
                .lib = lib,
                .include_dir = base_path,
            },
        };
    };
}

pub fn deinit(self: *Self) void {
    if (self.config) |config| {
        config.arena.deinit();
    }
}

pub fn link(self: Self, other: *LibExeObjStep) void {
    if (self.config) |config| {
        other.linkLibrary(config.lib);
        other.addIncludeDir(config.include_dir);
    } else {
        other.linkSystemLibrary("z");
        other.linkLibC();
    }
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
