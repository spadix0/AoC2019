pub const std = @import("std");
const io = std.io;
const fs = std.fs;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const parseInt = std.fmt.parseInt;
const File = fs.File;

pub const print = io.getStdOut().writer().print;
pub const debug = std.debug.print;
pub const expect = std.testing.expect;
pub const expectEqual = std.testing.expectEqual;
pub const expectEqualSlices = std.testing.expectEqualSlices;

pub var gpallocator = std.heap.GeneralPurposeAllocator(.{}){};
pub var gpalloc = &gpallocator.allocator;


pub fn expectOk(actual: anytype)
    @typeInfo(@TypeOf(actual)).ErrorUnion.payload
{
    if (actual) |payload| {
        return payload;
    } else |acterr| {
        std.debug.panic("unexpected error.{}", .{ @errorName(acterr) });
    }
}


pub const Reader = struct {
    data_alloc: *Allocator,
    file: File,
    stream: io.BufferedReader(4096, File.Reader),

    const LINE_MAX: usize = 256;

    pub fn fromArgv1() !Reader {
        var args = std.process.args();
        _ = args.skip();  // command

        var file = file:{
            const path = try args.next(gpalloc)
                orelse return error.MissingArgument;
            defer gpalloc.free(path);
            break :file try fs.cwd()
                .openFile(path, .{ .read = true });
        };

        return Reader {
            .data_alloc = gpalloc,
            .file = file,
            .stream = io.bufferedReader(file.reader()),
        };
    }

    pub fn fromPath(path: []const u8) !Reader {
        const file = try fs.cwd()
            .openFile(path, .{ .read = true });
        return Reader {
            .data_alloc = gpalloc,
            .file = file,
            .stream = io.bufferedReader(file.reader()),
        };
    }

    pub fn readLinesOf(self: *Reader, comptime T: type) ![]T {
        var buf: [LINE_MAX]u8 = undefined;
        var reader = self.file.reader();
        var list = ArrayList(T).init(self.data_alloc);
        errdefer list.deinit();

        while (try reader.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
            if (line.len == 0)
                break;
            try list.append(try parse1(T, line));
        }

        return list.toOwnedSlice();
    }
};

fn parse1(comptime T: type, str: []u8) !T {
    return switch (@typeInfo(T)) {
        .Int, .ComptimeInt =>
            try parseInt(T, str, 0),
        // FIXME others
        else => str,
    };
}
