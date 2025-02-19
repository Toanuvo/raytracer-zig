const std = @import("std");
const math = std.math;
const mem = std.mem;
const Allocator = mem.Allocator;
const Thread = std.Thread;
const config = @import("config");

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
vfov: f64,
lookfrom: V.Vec3, // Point camera is looking from
lookat: V.Vec3, // Point camera is looking at
vup: V.Vec3, // Camera-relative "up" direction
defocus_angle: f64,
focus_dist: f64,
alloc: Allocator,

defocus_disk_u: V.Vec3 = undefined,
defocus_disk_v: V.Vec3 = undefined,
u: V.Vec3 = undefined,
v: V.Vec3 = undefined,
w: V.Vec3 = undefined,
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

    s.center = s.lookfrom;

    const sf: f64 = @floatFromInt(s.samples_per_pixel);
    s.pixel_sample_scale = V.sc(1.0 / sf);

    const theta = math.degreesToRadians(s.vfov);
    const h = math.tan(theta / 2.0);
    const viewPortHeight = 2 * h * s.focus_dist;
    const viewPortWidth: f64 = viewPortHeight * (wf / hf);

    s.w = V.unit(s.lookfrom - s.lookat);
    s.u = V.unit(V.cross(s.vup, s.w));
    s.v = V.cross(s.w, s.u);

    // Calculate the vectors across the horizontal and down the vertical viewport edges.
    const viewport_u = V.sc(viewPortWidth) * s.u;
    const viewport_v = V.sc(viewPortHeight) * -s.v;

    // Calculate the camera defocus disk basis vectors.
    const defocus_radius = V.sc(s.focus_dist * math.tan(math.degreesToRadians(s.defocus_angle / 2)));
    s.defocus_disk_u = s.u * defocus_radius;
    s.defocus_disk_v = s.v * defocus_radius;

    // Calculate the horizontal and vertical delta vectors from pixel to pixel.
    s.pixel_delta_u = viewport_u / V.sc(wf);
    s.pixel_delta_v = viewport_v / V.sc(hf);

    // Calculate the location of the upper left pixel.
    const viewport_upper_left = s.center - (V.sc(s.focus_dist) * s.w) - viewport_u / V.sc(2) - viewport_v / V.sc(2);
    s.pixel00_loc = viewport_upper_left + V.sc(0.5) * (s.pixel_delta_u + s.pixel_delta_v);
}

const TdCtx = struct {
    cam: *Self,
    writer: std.io.AnyWriter,
    world: HL.HittableList,
    output: [][]u8,
    rows: []usize,
};

fn renderRow(
    s: *Self,
    output: [][]u8,
    world: HL.HittableList,
    row: usize,
    count: usize,
) !void {
    var buf = try std.ArrayList(u8).initCapacity(s.alloc, s.width * 5);
    //defer buf.deinit();

    for (row..row + count) |j| {
        for (0..s.width) |i| {
            var color = V.Vec3{ 0, 0, 0 };
            for (0..s.samples_per_pixel) |_| {
                const r = s.get_ray(@floatFromInt(i), @floatFromInt(j));
                color += ray_color(r, world, s.max_depth);
            }

            const pix = color * s.pixel_sample_scale;
            try V.print(pix, buf.writer());
        }
        output[j] = try buf.toOwnedSlice();
    }
}

pub fn renderThreaded(s: *Self, writer: anytype, world: HL.HittableList) !void {
    const ts = try std.Thread.getCpuCount() - 1;
    const per = s.height / ts;
    const extra = s.height % ts;

    const tds = try s.alloc.alloc(Thread, ts);
    const output = try s.alloc.alloc([]u8, s.height);

    for (tds, 0..) |*td, i| {
        const count = if (i == ts - 1) per + extra else per;
        td.* = try Thread.spawn(.{}, renderRow, .{ s, output, world, per * i, count });
    }
    for (tds) |t| {
        t.join();
    }

    for (output) |buf| {
        try writer.writeAll(buf);
    }
}

pub fn render(s: *Self, writer: anytype, world: HL.HittableList) !void {
    s.init();
    try writer.print("P3\n{d} {d}\n255\n", .{ s.width, s.height });

    if (config.threads) {
        try s.renderThreaded(writer, world);
        return;
    }

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
    const ray_origin = if (s.defocus_angle <= 0) s.center else s.defocus_disk_sample();
    const offset = sample_square();
    const pixel_sample = s.pixel00_loc +
        (V.sc(i + offset[0]) * s.pixel_delta_u) +
        (V.sc(j + offset[1]) * s.pixel_delta_v);

    return Ray.init(ray_origin, pixel_sample - ray_origin);
}

fn defocus_disk_sample(s: *Self) V.Vec3 {
    // Returns a random point in the camera defocus disk.
    const p = U.randVinUnitDisk();
    return s.center + (V.sc(p[0]) * s.defocus_disk_u) + (V.sc(p[1]) * s.defocus_disk_v);
}

fn sample_square() V.Vec3 {
    return V.Vec3{ U.randFloat() - 0.5, U.randFloat() - 0.5, 0 };
}

pub fn ray_color(r: Ray, world: HL.HittableList, depth: u64) V.Vec3 {
    if (depth <= 0) return V.Vec3{ 0, 0, 0 };
    var rec: H.HitRecord = undefined;
    if (world.hit(r, .{ .min = 0.001, .max = math.floatMax(f64) }, &rec)) {
        if (rec.mat.scatter(r, &rec)) |screc| {
            return screc.atten * ray_color(screc.scattered, world, depth - 1);
        }
        return V.Vec3{ 0, 0, 0 };
    }
    const ud = V.unit(r.dir);
    const a = 0.5 * (ud[1] + 1);
    const v = V.sc(1.0 - a) * V.Vec3{ 1.0, 1.0, 1.0 } + V.sc(a) * V.Vec3{ 0.5, 0.7, 1.0 };
    return v;
}
