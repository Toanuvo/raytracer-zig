const std = @import("std");
const simd = std.simd;
const Interval = @import("interval.zig");

const Vec = @This();
pub const Vec3 = @Vector(3, f64);
pub const z = Vec3{ 0, 0, 0 };

pub fn lensq(v: Vec3) f64 {
    return v[0] * v[0] +
        v[1] * v[1] +
        v[2] * v[2];
}

pub fn len(v: Vec3) f64 {
    return @sqrt(lensq(v));
}

pub fn dot(a: Vec3, b: Vec3) f64 {
    return @reduce(.Add, a * b);
}

pub fn cross(a: Vec3, b: Vec3) Vec3 {
    return Vec3{
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    };
}

pub fn dup(v: Vec3) Vec3 {
    return Vec3{ v[0], v[1], v[2] };
}

pub fn unit(v: Vec3) Vec3 {
    return v / sc(len(v));
}

pub fn sc(x: f64) Vec3 {
    return @splat(x);
}

pub fn near_zero(v: Vec3) bool {
    const e = sc(1e-8);
    return 3 == std.simd.countTrues(@abs(v) < e);
}

pub fn reflect(v: Vec3, n: Vec3) Vec3 {
    return v - sc(2 * dot(v, n)) * n;
}

fn linear_to_gamma(x: f64) f64 {
    return if (x > 0) @sqrt(x) else 0;
}

fn real_color_to_byte(c: f64) u8 {
    const r = Interval{ .min = 0, .max = 0.999 };
    return @intFromFloat(256 * r.clamp(linear_to_gamma(c)));
}

pub fn print(rgb: Vec3, writer: anytype) !void {
    const r: u8 = real_color_to_byte(rgb[0]);
    const g: u8 = real_color_to_byte(rgb[1]);
    const b: u8 = real_color_to_byte(rgb[2]);
    try writer.print("{d} {d} {d}\n", .{ r, g, b });
}
