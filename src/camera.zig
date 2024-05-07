const std = @import("std");
const math = std.math;

const Ray = @import("ray.zig");
const V = @import("vector.zig");
const H = @import("hittable.zig");
const HL = @import("hittableList.zig");
const U = @import("util.zig");
const stdout = std.io.getStdOut().writer();

width: u64,
aspectRatio: f64,
samples_per_pixel: u64,
max_depth: u64,

pixel_sample_scale: V.Vec3 = undefined,
height: u64 = undefined,
center: V.Vec3 = undefined, // Camera center
pixel00_loc: V.Vec3 = undefined, // Location of pixel 0, 0
pixel_delta_u: V.Vec3 = undefined, // Offset to pixel to the right
pixel_delta_v: V.Vec3 = undefined, // Offset to pixel below

const Self = @This();

fn init(s: *Self) void {
    const wf: f64 = @floatFromInt(s.width);
    const hf: f64 = (wf / s.aspectRatio);
    s.height = @intFromFloat(hf);

    const sf: f64 = @floatFromInt(s.samples_per_pixel);
    s.pixel_sample_scale = V.sc(1.0 / sf);

    const viewPortHeight: f64 = 2;
    const viewPortWidth: f64 = viewPortHeight * (wf / hf);
    const focal_length = 1.0;
    s.center = V.Vec3{ 0, 0, 0 };

    // Calculate the vectors across the horizontal and down the vertical viewport edges.
    const viewport_u = V.Vec3{ viewPortWidth, 0, 0 };
    const viewport_v = V.Vec3{ 0, -viewPortHeight, 0 };

    // Calculate the horizontal and vertical delta vectors from pixel to pixel.
    s.pixel_delta_u = viewport_u / V.sc(wf);
    s.pixel_delta_v = viewport_v / V.sc(hf);

    // Calculate the location of the upper left pixel.
    const viewport_upper_left = s.center - V.Vec3{ 0, 0, focal_length } - viewport_u / V.sc(2) - viewport_v / V.sc(2);
    s.pixel00_loc = viewport_upper_left + V.sc(0.5) * (s.pixel_delta_u + s.pixel_delta_v);
}

pub fn render(s: *Self, writer: anytype, world: *const HL.HittableList) !void {
    s.init();

    try writer.print("P3\n{d} {d}\n255\n", .{ s.width, s.height });

    for (0..s.height) |j| {
        if (j % 10 == 0)
            try stdout.print("remaining: {d}\n", .{s.height - j});

        for (0..s.width) |i| {
            var color = V.Vec3{ 0, 0, 0 };
            for (0..s.samples_per_pixel) |_| {
                const r = s.get_ray(@floatFromInt(i), @floatFromInt(j));
                color += ray_color(r, world, s.max_depth);
            }

            const pix = color * s.pixel_sample_scale;
            try V.print(pix, writer);
        }
    }
}

pub fn get_ray(s: *Self, i: f64, j: f64) Ray {
    const offset = sample_square();
    const pixel_sample = s.pixel00_loc +
        (V.sc(i + offset[0]) * s.pixel_delta_u) +
        (V.sc(j + offset[1]) * s.pixel_delta_v);

    return Ray.init(s.center, pixel_sample - s.center);
}

fn sample_square() V.Vec3 {
    return V.Vec3{ U.randFloat() - 0.5, U.randFloat() - 0.5, 0 };
}

pub fn ray_color(r: Ray, world: *const HL.HittableList, depth: u64) V.Vec3 {
    if (depth <= 0) return V.Vec3{ 0, 0, 0 };
    var rec: H.HitRecord = undefined;
    if (world.hit(r, .{ .min = 0.001, .max = math.floatMax(f64) }, &rec)) {
        const dir = rec.norm + U.randVUnit();
        return V.sc(0.5) * ray_color(Ray.init(rec.p, dir), world, depth - 1);
        //return V.sc(0.5) * (rec.norm + V.Vec3{ 1, 1, 1 });
    }
    const ud = V.unit(r.dir);
    const a = 0.5 * (ud[1] + 1);
    const v = V.sc(1.0 - a) * V.Vec3{ 1.0, 1.0, 1.0 } + V.sc(a) * V.Vec3{ 0.5, 0.7, 1.0 };
    return v;
}
