const Builder = @import("std").build.Builder;
const ZlibBuilder = @import("src/builder.zig");
const zlib_c = @import("deps.zig").pkgs.zlib_c;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    const zlib = ZlibBuilder.init(b.allocator, zlib_c.path);

    const lib = try zlib.addLibrary(b, .shared, target, mode);
    lib.install();
}
