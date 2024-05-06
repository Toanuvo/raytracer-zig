const std = @import("std");
const V = @import("vector.zig");

orig: V.Vec3,
dir: V.Vec3,

const Self = @This();
pub fn init(orig: V.Vec3, dir: V.Vec3) Self {
    return .{
        .orig = orig,
        .dir = dir,
    };
}

pub fn at(s: Self, t: f64) V.Vec3 {
    return s.orig + (s.dir * V.sc(t));
}
