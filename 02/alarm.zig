usingnamespace @import("aoc");

pub fn main() !void {
    const prog = try (try Reader.fromArgv1()).readCSVOf(u32);

    try print("part[1]: {}\n", .{
        try runCode(prog, 12, 2),
    });
    try print("part[2]: {d:04}\n", .{
        try findCodeSymbolic(prog, 19690720),
    });
}


pub fn runCode(prog: []const u32, noun: u32, verb: u32) !u32 {
    var cpu = try Intcode(u32).fromCopyOf(gpalloc, prog);
    defer cpu.deinit();
    cpu.mem[1] = noun;
    cpu.mem[2] = verb;
    cpu.run();
    return cpu.mem[0];
}


/// simple brute force search of input space for part 2
pub fn findCodeBrutish(prog: []const u32, target: u32) !u32 {
    var cpu = try Intcode(u32).fromCopyOf(gpalloc, prog);
    defer cpu.deinit();

    var noun: u32 = 0;
    while (noun <= 99) : (noun += 1) {
        var verb: u32 = 0;
        while (verb <= 99) : (verb += 1) {
            cpu.reset(prog);
            cpu.mem[1] = noun;
            cpu.mem[2] = verb;
            cpu.run();
            if (cpu.mem[0] == target)
                return 100*noun + verb;
        }
    }
    else
        std.debug.panic("code not found", .{});
}


/// alternative solution for part 2 which is linear in size of program
/// (under some assumptions).  simplified to be very input-specific and
/// still totally overkill for this problem...
pub fn findCodeSymbolic(prog: []const u32, target: u32) !u32 {
    return (try evalSymbolic(prog)).solve(target);
}

/// execute Intcode symbolically to generate linear expression to solve.
/// doesn't work if code uses complex self-modification (which it doesn't)
fn evalSymbolic(prog: []const u32) !Eqn {
    var mem = std.AutoHashMap(u32, Eqn).init(gpalloc);
    defer mem.deinit();
    try mem.ensureCapacity(@intCast(u32, prog.len / 4));

    try mem.put(1, .{ .c = 0, .a = 1 });
    try mem.put(2, .{ .c = 0, .b = 1 });

    const invalid = std.math.maxInt(u32);

    var pc: u32 = 0;
    while (pc < prog.len) {
        assert(!mem.contains(pc));
        const op = @intToEnum(Intcode(u32).Opcode, prog[pc]);
        switch (op) {
            .add, .mul => {
                const psrc0 = prog[pc+1];
                const psrc1 = prog[pc+2];
                const pdst = prog[pc+3];

                const src0 = if (mem.get(psrc0)) |x| x
                    else Eqn { .c = prog[psrc0] };
                const src1 = if (mem.get(psrc1)) |y| y
                    else Eqn { .c = prog[psrc1] };
                assert(!mem.contains(pc+3)); // too much

                // NB first op can't be calc this way - but never used so ok
                const dst = if (pc == 0)
                        Eqn { .a = invalid, .b = invalid, .c = invalid }
                    else if (op == .add) // add
                        Eqn {
                            .a = src0.a + src1.a,
                            .b = src0.b + src1.b,
                            .c = src0.c + src1.c,
                        }
                    else mul:{
                        // doesn't handle arbitrary factors
                        assert((src0.a == 0 and src0.b == 0) or
                               (src1.a == 0 and src1.b == 0));
                        break :mul Eqn {
                            .a = src0.a*src1.c + src0.c*src1.a,
                            .b = src0.b*src1.c + src0.c*src1.b,
                            .c = src0.c * src1.c,
                        };
                    };

                try mem.put(pdst, dst);
                pc += 4;
            },
            .end => break,
        }
    }

    return mem.get(0).?;
}

/// a*noun + b*verb + c
/// assume other factors never generated (because they're not)
const Eqn = struct {
    c: u32,         // constant
    a: u32 = 0,     // noun factor
    b: u32 = 0,     // verb factor

    /// find noun*100 + verb that satisfies
    /// a*noun + b*verb + c = target where 0 <= noun, verb <= 99
    fn solve(self: @This(), target: u32) u32 {
        const a = self.a;
        const b = self.b;
        const c = target - self.c;

        assert(a > 0);
        assert(b > 0);
        var nmax = c / a;
        var vmax = c / b;
        const dndv = b / a;
        const dvdn = a / b;

        var noun: u32 = undefined;
        var verb: u32 = undefined;
        if (a >= b) {
            const nv = linsolve(nmax, dndv, vmax, dvdn);
            noun = nv.x;
            verb = nv.y;
        } else {
            const vn = linsolve(vmax, dvdn, nmax, dndv);
            verb = vn.x;
            noun = vn.y;
        }

        assert(0 <= noun and noun <= 99);
        assert(0 <= verb and verb <= 99);
        assert(a*noun + b*verb + self.c == target);
        return noun*100 + verb;
    }

    fn linsolve(xhi: u32, dxdy: u32, ymax: u32, dydx: u32)
        struct { x: u32, y: u32 }
    {
        const xmax = math.min(xhi, 99);
        var x = xmax - math.min(xmax, 99*dxdy);
        while (x < xmax and dydx*x + 99 < ymax)
            x += 1;
        return .{ .x = x, .y = ymax - math.min(dydx*x, ymax) };
    }
};


//----------------------------------------------------------------------------
fn testSmall(prog: anytype, exp: anytype) Intcode(u32) {
    var cpu = expectOk(
        Intcode(u32).fromCopyOf(std.testing.allocator, &prog)
    );
    defer cpu.deinit();
    cpu.run();
    expectEqualSlices(u32, &exp, cpu.mem);
    return cpu;
}


test "ex0[1]" {
    _ = testSmall(
        [_]u32{ 1,9,10,3,2,3,11,0,99,30,40,50 },
        [_]u32{ 3500,9,10,70,2,3,11,0,99,30,40,50 },
    );
}

test "ex1[1]" {
    _ = testSmall([_]u32{ 1,0,0,0,99 }, [_]u32{ 2,0,0,0,99 });
}

test "ex2[1]" {
    _ = testSmall([_]u32{ 2,3,0,3,99 }, [_]u32{ 2,3,0,6,99 });
}

test "ex3[1]" {
    _ = testSmall([_]u32{ 2,4,4,5,99,0 }, [_]u32{ 2,4,4,5,99,9801 });
}

test "ex4[1]" {
    _ = testSmall(
        [_]u32{ 1,1,1,4,99,5,6,0,99 },
        [_]u32{ 30,1,1,4,2,5,6,0,99 }
    );
}

test "answer[1]" {
    const prog = try (try Reader.fromPath("02/input.txt")).readCSVOf(u32);
    expectEqual(@as(u32, 3562672), try runCode(prog, 12, 2));
}

test "answer[2]" {
    const prog = try (try Reader.fromPath("02/input.txt")).readCSVOf(u32);
    expectEqual(@as(u32, 8250), try findCodeBrutish(prog, 19690720));
    expectEqual(@as(u32, 8250), try findCodeSymbolic(prog, 19690720));
}
