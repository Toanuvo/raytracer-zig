const std = @import("std");
const fs = std.fs;
const V = @import("vector.zig");

pub const width = 256;
pub const height = 256;

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gpa.detectLeaks();
    const alloc = gpa.allocator();
    const fname = try std.fmt.allocPrint(alloc, "{d}x{d}.ppm", .{ width, height });
    defer alloc.free(fname);
    const picDir = try fs.cwd().openDir("pics", .{});
    const f = try picDir.createFile(fname, .{});
    defer f.close();
    const fw = f.writer();

    try fw.print("P3\n{d} {d}\n255\n", .{ width, height });

    for (0..height) |j| {
        if (j % 10 == 0)
            try stdout.print("remaining: {d}\n", .{height - j});

        for (0..width) |i| {
            const iF: f64 = @floatFromInt(i);
            const jF: f64 = @floatFromInt(j);
            const pix = V.Vec3{ iF / (width - 1), jF / (height - 1), 0.0 };
            try V.print(pix, fw);
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
