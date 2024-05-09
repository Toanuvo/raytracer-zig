const std = @import("std");

const V = @import("vector.zig");
const Ray = @import("ray.zig");
const H = @import("hittable.zig");
const U = @import("util.zig");

const ScatterFn = fn (*const Material, Ray, *H.HitRecord) ?ScatterRec;
const ScatterRec = struct { atten: V.Vec3, scattered: Ray };
scatterfn: *const ScatterFn,

pub fn scatter(s: *const Material, in: Ray, rec: *H.HitRecord) ?ScatterRec {
    return s.scatterfn(s, in, rec);
}

pub const Material = @This();

pub const Lambertian = struct {
    mat: Material,
    albedo: V.Vec3,

    const Self = @This();

    pub fn init(albedo: V.Vec3) Self {
        return .{
            .albedo = albedo,
            .mat = .{ .scatterfn = &Self.scatter },
        };
    }

    pub fn scatter(mat: *const Material, in: Ray, rec: *H.HitRecord) ?ScatterRec {
        _ = in; // autofix
        const s: *const Self = @alignCast(@fieldParentPtr("mat", mat));
        var scatter_direction = rec.norm + U.randVUnit();
        if (V.near_zero(scatter_direction))
            scatter_direction = rec.norm;
        return .{
            .atten = s.albedo,
            .scattered = Ray.init(rec.p, scatter_direction),
        };
    }
};

pub const Metal = struct {
    mat: Material,
    albedo: V.Vec3,
    fuzz: V.Vec3,

    const Self = @This();

    pub fn init(albedo: V.Vec3, fuzz: f64) Self {
        return .{
            .fuzz = V.sc(fuzz),
            .albedo = albedo,
            .mat = .{ .scatterfn = &Self.scatter },
        };
    }

    pub fn scatter(mat: *const Material, in: Ray, rec: *H.HitRecord) ?ScatterRec {
        const s: *const Self = @alignCast(@fieldParentPtr("mat", mat));

        const reflected = V.unit(V.reflect(in.dir, rec.norm)) + (s.fuzz * U.randVUnit());
        return if (V.dot(reflected, rec.norm) > 0) .{
            .scattered = Ray.init(rec.p, reflected),
            .atten = s.albedo,
        } else null;
    }
};

pub const Dielectric = struct {
    mat: Material,
    refIndex: f64,

    const Self = @This();

    pub fn init(refIndex: f64) Self {
        return .{
            .refIndex = refIndex,
            .mat = .{ .scatterfn = &Self.scatter },
        };
    }

    pub fn scatter(mat: *const Material, in: Ray, rec: *H.HitRecord) ?ScatterRec {
        const s: *const Self = @alignCast(@fieldParentPtr("mat", mat));

        const ri = if (rec.front_face) (1.0 / s.refIndex) else s.refIndex;
        const unit_direction = V.unit(in.dir);

        const cos_theta = @min(V.dot(-unit_direction, rec.norm), 1.0);
        const sin_theta = @sqrt(1.0 - cos_theta * cos_theta);
        const reflect = ri * sin_theta > 1.0;

        const dir = if (reflect or reflectance(cos_theta, ri) > U.randFloat())
            V.reflect(unit_direction, rec.norm)
        else
            V.refract(unit_direction, rec.norm, ri);

        return .{
            .atten = V.Vec3{ 1.0, 1.0, 1.0 },
            .scattered = Ray.init(rec.p, dir),
        };
    }

    fn reflectance(cos: f64, refraction_idx: f64) f64 {
        var r0 = (1 - refraction_idx) / (1 + refraction_idx);
        r0 = r0 * r0;
        return r0 + (1 - r0) * std.math.pow(f64, (1 - cos), 5);
    }
};
