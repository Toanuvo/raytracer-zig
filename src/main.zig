const std = @import("std");
const math = std.math;
const fs = std.fs;
const V = @import("vector.zig");
const H = @import("hittable.zig");
const HL = @import("hittableList.zig");
const Ray = @import("ray.zig");
const Cam = @import("camera.zig");
const U = @import("util.zig");
const Mat = @import("material.zig");

pub const width: u64 = 600;
pub const aspectRatio: f64 = 16.0 / 9.0;
pub const height: u64 = @intFromFloat(width / aspectRatio);
pub const samples_per_pixel = 100;

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    var r = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
    U.rand = r.random();
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gpa.detectLeaks();
    const alloc = gpa.allocator();
    const fname = try std.fmt.allocPrint(alloc, "{d}x{d}.ppm", .{ width, height });
    defer alloc.free(fname);
    const picDir = try fs.cwd().openDir("pics", .{});
    const f = try picDir.createFile(fname, .{});
    defer f.close();
    const fw = f.writer();

    var world = HL.HittableList{ .objs = HL.HitArrList.init(alloc) };
    const material_ground = Mat.Lambertian.init(V.Vec3{ 0.8, 0.8, 0.0 });
    const material_center = Mat.Lambertian.init(V.Vec3{ 0.1, 0.2, 0.5 });
    //const material_left = Mat.Metal.init(V.Vec3{ 0.8, 0.8, 0.8 }, 0.3);
    const material_left = Mat.Dielectric.init(1.5);
    const material_bubble = Mat.Dielectric.init(1.0 / 1.5);
    const material_right = Mat.Metal.init(V.Vec3{ 0.8, 0.6, 0.2 }, 1);

    try world.append(&H.Sphere.init(V.Vec3{ 0.0, -100.5, -1.0 }, 100.0, &material_ground.mat).hittable);
    try world.append(&H.Sphere.init(V.Vec3{ 0.0, 0.0, -1.2 }, 0.5, &material_center.mat).hittable);
    try world.append(&H.Sphere.init(V.Vec3{ -1.0, 0.0, -1.0 }, 0.5, &material_left.mat).hittable);
    try world.append(&H.Sphere.init(V.Vec3{ -1.0, 0.0, -1.0 }, 0.4, &material_bubble.mat).hittable);
    try world.append(&H.Sphere.init(V.Vec3{ 1.0, 0.0, -1.0 }, 0.5, &material_right.mat).hittable);

    defer world.objs.deinit();
    //try world.append(&H.Sphere.init(V.Vec3{ 0, 0, -1 }, 0.5).hittable);
    //try world.append(&H.Sphere.init(V.Vec3{ 0, -100.5, -1 }, 100).hittable);

    var cam = Cam{
        .width = width,
        .aspectRatio = aspectRatio,
        .samples_per_pixel = samples_per_pixel,
        .max_depth = 50,
        .vfov = 90,
        .lookfrom = V.Vec3{ -2, 2, 1 },
        .lookat = V.Vec3{ 0, 0, -1 },
        .vup = V.Vec3{ 0, 1, 0 },
    };

    try cam.render(fw, &world);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
