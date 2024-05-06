const std = @import("std");
const math = std.math;

const Ray = @import("ray.zig");
const V = @import("vector.zig");
const H = @import("hittable.zig");
const HL = @import("hittableList.zig");
const stdout = std.io.getStdOut().writer();

width: u64 = 400,
aspectRatio: f64 = 16.0 / 9.0,
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
            const pixel_center = s.pixel00_loc + (V.sc(@floatFromInt(i)) * s.pixel_delta_u) + (V.sc(@floatFromInt(j)) * s.pixel_delta_v);
            const ray_direction = pixel_center - s.center;
            const r = Ray.init(s.center, ray_direction);

            const pix = ray_color(r, world);
            try V.print(pix, writer);
        }
    }
}

pub fn ray_color(r: Ray, world: *const HL.HittableList) V.Vec3 {
    var rec: H.HitRecord = undefined;
    if (world.hit(r, .{ .min = 0, .max = math.floatMax(f64) }, &rec)) {
        return V.sc(0.5) * (rec.norm + V.Vec3{ 1, 1, 1 });
    }

    const ud = V.unit(r.dir);
    const a = 0.5 * (ud[1] + 1);
    return V.sc(1.0 - a) * V.Vec3{ 1.0, 1.0, 1.0 } + V.sc(a) * V.Vec3{ 0.5, 0.7, 1.0 };
}
