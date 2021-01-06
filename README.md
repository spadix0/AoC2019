# AoC 2019

Solutions to [Advent of Code 2019] in [Zig], for the purpose of trying out Zig.


### Build

You will need [Zig], then just:

    zig build

Executables for each day are deposited in `zig-cache/bin/`.


### Run

To run the solution for a specific day:

    zig build run01 -- 01/input.txt

or just run the binary.  Either way, make sure to provide some input.


### Test

Run all the tests!

    zig build regress

or a specific day:

    zig build test01


[Advent of Code 2019]: https://adventofcode.com/2019
[Zig]: https://ziglang.org
