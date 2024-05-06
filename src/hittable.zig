const std = @import("std");
const V = @import("vector.zig");
const R = @import("ray.zig");

pub const HitRecord = struct {
    p: V.Vec3,
    norm: V.Vec3,
    t: f64,
    front_face: bool,

    const Self = @This();
    pub fn setFaceNormal(s: *Self, r: R.Ray, outNorm: V.Vec3) void {
        s.front_face = V.dot(r.dir, outNorm) < 0;
        s.norm = if (s.front_face) outNorm else -outNorm;
    }
};

const HitFn = fn (h: *const Hittable, r: R.Ray, ray_tmin: f64, ray_tmax: f64, hr: *HitRecord) bool;

pub const Hittable = struct {
    hitfn: *const HitFn,

    const Self = @This();
    pub fn hit(s: *const Self, r: R.Ray, ray_tmin: f64, ray_tmax: f64, hr: *HitRecord) bool {
        return s.hitfn(s, r, ray_tmin, ray_tmax, hr);
    }
};

pub const Sphere = struct {
    cent: V.Vec3,
    rad: f64,
    hittable: Hittable,

    const Self = @This();
    pub fn init(cent: V.Vec3, r: f64) Self {
        return .{
            .cent = cent,
            .rad = r,
            .hittable = .{ .hitfn = &hit },
        };
    }

    pub fn hit(hb: *const Hittable, r: R.Ray, ray_tmin: f64, ray_tmax: f64, rec: *HitRecord) bool {
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
        if (root <= ray_tmin or ray_tmax <= root) {
            root = (h + sqrtd) / a;
            if (root <= ray_tmin or ray_tmax <= root)
                return false;
        }

        rec.t = root;
        rec.p = r.at(rec.t);
        rec.norm = (rec.p - s.cent) / V.sc(s.rad);
        const outNorm = (rec.p - s.cent) / V.sc(s.rad);
        rec.setFaceNormal(r, outNorm);
        return true;
    }
};
