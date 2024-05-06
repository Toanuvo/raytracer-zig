const std = @import("std");

const maxf = std.math.floatMax(f64);
const minf = std.math.floatMin(f64);

min: f64 = minf,
max: f64 = maxf,

const Self = @This();
pub fn sz(s: Self) f64 {
    return s.max - s.min;
}

pub fn cont(s: Self, x: f64) bool {
    return s.min <= x and x <= s.max;
}

pub fn surr(s: Self, x: f64) bool {
    return s.min < x and x < s.max;
}

pub fn clamp(s: Self, x: f64) f64 {
    return std.math.clamp(x, s.min, s.max);
}
