const std = @import("std");
const Builder = std.build.Builder;

var regress: *std.build.Step = undefined;


pub fn build(b: *Builder) void {
    regress = b.step("regress", "Run tests for all days");

    addexe(b, 1, "fuel");
}


pub fn addexe(b: *Builder, iday: u32, name: []const u8) void {
    const day = b.fmt("{d:0>2}", .{ iday });
    const src = b.fmt("{}/{}.zig", .{ day, name });

    const test_ = b.addTest(src);
    test_.setBuildMode(b.standardReleaseOptions());
    test_.addPackagePath("aoc", "aoc.zig");
    regress.dependOn(&test_.step);
    b.step(
            b.fmt("test{}", .{ day }),
            b.fmt("Run tests for day {} ({})", .{ iday, name }))
        .dependOn(&test_.step);

    const exe = b.addExecutable(b.fmt("{}-{}", .{ day, name }), src);
    exe.setBuildMode(b.standardReleaseOptions());
    exe.addPackagePath("aoc", "aoc.zig");
    exe.install();
    b.default_step.dependOn(&exe.step);

    const run = exe.run();
    if (b.args) |args|
        run.addArgs(args);

    b.step(
            b.fmt("run{}", .{ day }),
            b.fmt("Run day {} ({})", .{ iday, name }))
        .dependOn(&run.step);
}
