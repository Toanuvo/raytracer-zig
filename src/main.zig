const std = @import("std");
const fs = std.fs;
const V = @import("vector.zig");
const Ray = @import("ray.zig").Ray;

pub const width: u64 = 400;
pub const aspectRatio: f64 = 16.0 / 9.0;
pub const height: u64 = @intFromFloat(width / aspectRatio);

pub const viewPortHeight: f64 = 2;
pub const viewPortWidth: f64 = viewPortHeight * (@as(f64, width) / height);
const focal_length = 1.0;
const camera_center = V.Vec3{ 0, 0, 0 };

// Calculate the vectors across the horizontal and down the vertical viewport edges.
const viewport_u = V.Vec3{ viewPortWidth, 0, 0 };
const viewport_v = V.Vec3{ 0, -viewPortHeight, 0 };

// Calculate the horizontal and vertical delta vectors from pixel to pixel.
const pixel_delta_u = viewport_u / V.sc(width);
const pixel_delta_v = viewport_v / V.sc(height);

// Calculate the location of the upper left pixel.
const viewport_upper_left = camera_center - V.Vec3{ 0, 0, focal_length } - viewport_u / V.sc(2) - viewport_v / V.sc(2);
const pixel00_loc = viewport_upper_left + V.sc(0.5) * (pixel_delta_u + pixel_delta_v);

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gpa.detectLeaks();
    const alloc = gpa.allocator();
    const fname = try std.fmt.allocPrint(alloc, "{d}x{d}.ppm", .{ width, height });
    defer alloc.free(fname);
    const picDir = try fs.cwd().openDir("pics", .{});
    const f = try picDir.createFile(fname, .{});
    defer f.close();
    const fw = f.writer();

    std.debug.print("val: {any}\n", .{viewPortWidth});

    try fw.print("P3\n{d} {d}\n255\n", .{ width, height });

    for (0..height) |j| {
        if (j % 10 == 0)
            try stdout.print("remaining: {d}\n", .{height - j});

        for (0..width) |i| {
            const pixel_center = pixel00_loc + (V.sc(@floatFromInt(i)) * pixel_delta_u) + (V.sc(@floatFromInt(j)) * pixel_delta_v);
            const ray_direction = pixel_center - camera_center;
            const r = Ray.init(camera_center, ray_direction);

            const pix = ray_color(r);
            if (i == 0) {
                std.debug.print("val: {any}\n", .{pix});
            }
            try V.print(pix, fw);
        }
    }
}

fn ray_color(r: Ray) V.Vec3 {
    const t = hit_sphere(V.Vec3{ 0, 0, -1 }, 0.5, r);
    if (t > 0) {
        const N = V.unit(r.at(t) - V.Vec3{ 0, 0, -1 });
        return (N + V.sc(1)) / V.sc(2);
    }
    const ud = V.unit(r.dir);
    const a = 0.5 * (ud[1] + 1);
    return V.sc(1.0 - a) * V.Vec3{ 1.0, 1.0, 1.0 } + V.sc(a) * V.Vec3{ 0.5, 0.7, 1.0 };
}

fn hit_sphere(center: V.Vec3, rad: f64, r: Ray) f64 {
    const oc = center - r.orig;
    const a = V.lensq(r.dir);
    const h = V.dot(r.dir, oc);
    const c = V.lensq(oc) - rad * rad;

    const discriminant = h * h - a * c;
    if (discriminant < 0) {
        return -1;
    } else {
        return (h - @sqrt(discriminant)) / a;
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
