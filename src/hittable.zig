const std = @import("std");
const V = @import("vector.zig");
const Ray = @import("ray.zig");
const Interval = @import("interval.zig");
const Mat = @import("material.zig");

pub const HitRecord = struct {
    p: V.Vec3,
    norm: V.Vec3,
    t: f64,
    front_face: bool = undefined,
    mat: *const Mat,

    const Self = @This();
    pub fn setFaceNormal(s: *Self, r: Ray, outNorm: V.Vec3) void {
        s.front_face = V.dot(r.dir, outNorm) < 0;
        s.norm = if (s.front_face) outNorm else -outNorm;
    }
};

const HitFn = fn (h: *const Hittable, r: Ray, ray_t: Interval, hr: *HitRecord) bool;

pub const Hittable = struct {
    hitfn: *const HitFn,

    const Self = @This();
    pub fn hit(s: *const Self, r: Ray, ray_t: Interval, hr: *HitRecord) bool {
        return s.hitfn(s, r, ray_t, hr);
    }
};

pub const Sphere = struct {
    cent: V.Vec3,
    rad: f64,
    hittable: Hittable,
    mat: *const Mat,

    const Self = @This();
    pub fn init(cent: V.Vec3, r: f64, mat: *const Mat) Self {
        return .{
            .cent = cent,
            .rad = r,
            .hittable = .{ .hitfn = &hit },
            .mat = mat,
        };
    }

    pub fn hit(hb: *const Hittable, r: Ray, ray_t: Interval, rec: *HitRecord) bool {
        const s: *const Self = @alignCast(@fieldParentPtr("hittable", hb));

        const oc = s.cent - r.orig;
        const a = V.lensq(r.dir);
        const h = V.dot(r.dir, oc);
        const c = V.lensq(oc) - s.rad * s.rad;

        const discriminant = h * h - a * c;
        if (discriminant < 0)
            return false;

        const sqrtd = @sqrt(discriminant);
        // Find the nearest root that lies in the acceptable range.
        var root = (h - sqrtd) / a;
        if (!ray_t.surr(root)) {
            root = (h + sqrtd) / a;
            if (!ray_t.surr(root))
                return false;
        }

        rec.* = .{
            .t = root,
            .p = r.at(root),
            .norm = (r.at(root) - s.cent) / V.sc(s.rad),
            .mat = s.mat,
        };
        const outNorm = (rec.p - s.cent) / V.sc(s.rad);
        rec.setFaceNormal(r, outNorm);
        return true;
    }
};
