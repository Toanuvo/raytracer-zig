const std = @import("std");
const H = @import("hittable.zig");
const V = @import("vector.zig");
const R = @import("ray.zig");
const Allocator = std.mem.Allocator;
pub const HitArrList = std.ArrayList(*const H.Hittable);

pub const HittableList = struct {
    objs: HitArrList,

    const Self = @This();

    pub fn append(s: *Self, h: *const H.Hittable) !void {
        try s.objs.append(h);
    }

    pub fn hit(s: *const Self, r: R.Ray, ray_tmin: f64, ray_tmax: f64, rec: *H.HitRecord) bool {
        var temp_rec: H.HitRecord = undefined;
        var hit_anything = false;
        var closest_so_far = ray_tmax;

        for (s.objs.items) |o| {
            if (o.hit(r, ray_tmin, closest_so_far, &temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec.* = temp_rec;
            }
        }
        return hit_anything;
    }
};
