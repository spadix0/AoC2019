const std = @import("std");

var regress: *std.build.Step = undefined;


pub fn build(b: *std.build.Builder) void {
    regress = b.step("regress", "Run tests for all days");

    addexe(b, 1, "fuel");
    addexe(b, 2, "alarm");

    b.step("clean", "Trash the cache")
        .dependOn(&b.addRemoveDirTree(b.cache_root).step);
}


pub fn addexe(b: anytype, iday: u32, name: []const u8) void {
    const day = b.fmt("{d:0>2}", .{ iday });
    const src = b.fmt("{s}/{s}.zig", .{ day, name });

    const test_ = b.addTest(src);
    test_.setBuildMode(b.standardReleaseOptions());
    test_.addPackagePath("aoc", "aoc.zig");
    regress.dependOn(&test_.step);
    b.step(
            b.fmt("test{s}", .{ day }),
            b.fmt("Run tests for day {d} ({s})", .{ iday, name }))
        .dependOn(&test_.step);

    const exe = b.addExecutable(b.fmt("{s}-{s}", .{ day, name }), src);
    exe.setBuildMode(b.standardReleaseOptions());
    exe.addPackagePath("aoc", "aoc.zig");
    exe.install();
    b.default_step.dependOn(&exe.step);

    const run = exe.run();
    if (b.args) |args|
        run.addArgs(args);

    b.step(
            b.fmt("run{s}", .{ day }),
            b.fmt("Run day {d} ({s})", .{ iday, name }))
        .dependOn(&run.step);
}
