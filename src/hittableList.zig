const std = @import("std");
const H = @import("hittable.zig");
const V = @import("vector.zig");
const Ray = @import("ray.zig");
const Allocator = std.mem.Allocator;
const Interval = @import("interval.zig");
pub const HitArrList = std.ArrayList(*const H.Hittable);

pub const HittableList = struct {
    objs: HitArrList,

    const Self = @This();

    pub fn append(s: *Self, h: *const H.Hittable) !void {
        try s.objs.append(h);
    }

    pub fn hit(s: *const Self, r: Ray, ray_t: Interval, rec: *H.HitRecord) bool {
        var temp_rec: H.HitRecord = undefined;
        var hit_anything = false;
        var closest_so_far = ray_t.max;

        for (s.objs.items) |o| {
            if (o.hit(r, .{ .max = closest_so_far, .min = ray_t.min }, &temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec.* = temp_rec;
            }
        }
        return hit_anything;
    }
};
