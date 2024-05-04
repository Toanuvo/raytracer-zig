const std = @import("std");
const simd = std.simd;

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

pub fn unit(v: Vec3) Vec3 {
    return v / sc(len(v));
}

pub fn sc(x: f64) Vec3 {
    return @splat(x);
}

pub fn print(v: Vec3, writer: anytype) !void {
    const bv = v * sc(255.999);
    const r: u8 = @intFromFloat(bv[0]);
    const g: u8 = @intFromFloat(bv[1]);
    const b: u8 = @intFromFloat(bv[2]);
    try writer.print("{d} {d} {d}\n", .{ r, g, b });
}
