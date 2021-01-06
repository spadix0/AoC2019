usingnamespace @import("aoc");

pub fn main() !void {
    const masses = try (try Reader.fromArgv1()).readLinesOf(u32);
    try print("part[1]: {}\n", .{ mapsum(u64, masses, calcFuel) });
    try print("part[2]: {}\n", .{ mapsum(u64, masses, calcFuelRec) });
}


pub fn mapsum(comptime T: type, slice: anytype, map: anytype) T {
    var acc: T = 0;
    for (slice) |x|
        acc += map(x);
    return acc;
}


pub fn calcFuel(mass: anytype) @TypeOf(mass) {
    const x = mass / 3;
    return if (x >= 2) x - 2 else 0;
}


pub fn calcFuelRec(mass: anytype) @TypeOf(mass) {
    var m = mass;
    var fuel: @TypeOf(mass) = 0;
    while (m > 0) {
        m = calcFuel(m);
        fuel += m;
    }
    return fuel;
}


//----------------------------------------------------------------------------
test "calcFuel" {
    expectEqual(@as(u32, 2), calcFuel(12));
    expectEqual(@as(u32, 2), calcFuel(14));
    expectEqual(@as(u32, 654), calcFuel(1969));
    expectEqual(@as(u32, 33583), calcFuel(100756));
}

test "calcFuelRec" {
    expectEqual(@as(u32, 2), calcFuelRec(14));
    expectEqual(@as(u32, 966), calcFuelRec(1969));
    expectEqual(@as(u32, 50346), calcFuelRec(100756));
}

test "answer[1]" {
    const masses = try (try Reader.fromPath("01/input.txt")).readLinesOf(u32);
    expectEqual(@as(u64, 3416712), mapsum(u64, masses, calcFuel));
}

test "answer[2]" {
    const masses = try (try Reader.fromPath("01/input.txt")).readLinesOf(u32);
    expectEqual(@as(u64, 5122170), mapsum(u64, masses, calcFuelRec));
}
