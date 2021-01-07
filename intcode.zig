const std = @import("std");
const Allocator = std.mem.Allocator;
const panic = std.debug.panic;


pub fn Intcode(comptime T: type) type {
    return struct {
        allocator: *Allocator,
        mem: []T,
        pc: usize = 0,

        pub const Opcode = enum(T) {
            add = 1,
            mul = 2,
            end = 99,
        };

        pub fn fromCopyOf(allocator: *Allocator, src: []const T) !@This() {
            var mem = try allocator.alloc(T, src.len);
            std.mem.copy(T, mem, src);
            return @This() {
                .allocator = allocator,
                .mem = mem,
            };
        }

        pub fn deinit(self: *@This()) void {
            self.allocator.free(self.mem);
        }

        pub fn reset(self: *@This(), src: []const T) void {
            std.mem.copy(u32, self.mem, src);
            self.pc = 0;
        }

        pub fn run(self: *@This()) void {
            while (self.step()) { }
        }

        pub fn step(self: *@This()) bool {
            var mem = self.mem;
            var pc = self.pc;
            if (pc >= mem.len)
                return false;

            switch (@intToEnum(Opcode, mem[pc])) {
                .add => {
                    mem[mem[pc+3]] = mem[mem[pc+1]] + mem[mem[pc+2]];
                    pc += 4;
                },
                .mul => {
                    mem[mem[pc+3]] = mem[mem[pc+1]] * mem[mem[pc+2]];
                    pc += 4;
                },
                .end => return false,
            }

            self.pc = pc;
            return true;
        }
    };
}
