const std = @import("std");
const H = @import("hittable.zig");
const V = @import("vector.zig");
const Ray = @import("ray.zig");
const Allocator = std.mem.Allocator;
const Interval = @import("interval.zig");
pub const HitArrList = std.ArrayList(*const H.Hittable);

pub fn HittableStorage(Objs: []const type) type {
    const Arr = std.ArrayListUnmanaged;
    return struct {
        alloc: Allocator,
        arrs: [Objs.len]*align(8) anyopaque = undefined,

        const Self = @This();

        pub fn init(
            alloc: Allocator,
        ) !Self {
            var s: Self = .{ .alloc = alloc };

            inline for (&s.arrs, Objs) |*arr, tp| {
                const t = std.ArrayListUnmanaged(tp);
                const p = try alloc.create(t);
                p.* = t{}; // initalize it;
                arr.* = p;
            }
            return s;
        }

        pub fn append(s: *Self, o: anytype) !void {
            const arr = s.getArr(@TypeOf(o));
            try arr.append(s.alloc, o);
        }

        pub fn hittables(s: *Self) !HittableList {
            var hitls = Arr(*const H.Hittable){};
            inline for (Objs) |t| {
                const arr = s.getArr(t);
                for (arr.items) |*i| {
                    try hitls.append(s.alloc, &i.hittable);
                }
            }
            return .{ .objs = hitls.items };
        }

        fn getArr(s: *Self, tp: type) *Arr(tp) {
            inline for (Objs, &s.arrs) |t, arr| {
                if (t == tp) {
                    return @ptrCast(arr);
                }
            }
        }
    };
}

pub const HittableList = struct {
    objs: []*const H.Hittable,

    const Self = @This();
    pub fn hit(s: *const Self, r: Ray, ray_t: Interval, rec: *H.HitRecord) bool {
        var temp_rec: H.HitRecord = undefined;
        var hit_anything = false;
        var closest_so_far = ray_t.max;

        for (s.objs) |o| {
            if (o.hit(r, .{ .max = closest_so_far, .min = ray_t.min }, &temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec.* = temp_rec;
            }
        }
        return hit_anything;
    }
};
