const std = @import("std");

pub var rand: std.Random = undefined;

pub fn randRange(min: f64, max: f64) f64 {
    return min + (max - min) * rand.float(f64);
}
