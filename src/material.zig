const std = @import("std");
const Allocator = std.mem.Allocator;

const V = @import("vector.zig");
const Ray = @import("ray.zig");
const H = @import("hittable.zig");
const U = @import("util.zig");

const ScatterRec = struct { atten: V.Vec3, scattered: Ray };

pub const Mat = union(enum) {
    Lambertian: struct {
        albedo: V.Vec3,

        const Self = @This();
        pub fn scatter(s: *const Self, in: Ray, rec: *H.HitRecord) ?ScatterRec {
            _ = in; // autofix
            var scatter_direction = rec.norm + U.randVUnit();
            if (V.near_zero(scatter_direction))
                scatter_direction = rec.norm;
            return .{
                .atten = s.albedo,
                .scattered = Ray.init(rec.p, scatter_direction),
            };
        }
    },

    Metal: struct {
        albedo: V.Vec3,
        fuzz: V.Vec3,

        const Self = @This();
        pub fn scatter(s: *const Self, in: Ray, rec: *H.HitRecord) ?ScatterRec {
            const reflected = V.unit(V.reflect(in.dir, rec.norm)) + (s.fuzz * U.randVUnit());
            return if (V.dot(reflected, rec.norm) > 0) .{
                .scattered = Ray.init(rec.p, reflected),
                .atten = s.albedo,
            } else null;
        }
    },

    Dielectric: struct {
        refIndex: f64,

        const Self = @This();

        pub fn scatter(s: *const Self, in: Ray, rec: *H.HitRecord) ?ScatterRec {
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
    },

    pub fn scatter(s: *const Mat, in: Ray, rec: *H.HitRecord) ?ScatterRec {
        return switch (std.meta.activeTag(s.*)) {
            .Lambertian => s.Lambertian.scatter(in, rec),
            .Metal => s.Metal.scatter(in, rec),
            .Dielectric => s.Dielectric.scatter(in, rec),
        };
    }
};
