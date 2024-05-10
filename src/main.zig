const std = @import("std");
const math = std;
const fs = std.fs;
const V = @import("vector.zig");
const H = @import("hittable.zig");
const HL = @import("hittableList.zig");
const Ray = @import("ray.zig");
const Cam = @import("camera.zig");
const U = @import("util.zig");
const M = @import("material.zig");

pub const width: u64 = 400;
pub const aspectRatio: f64 = 16.0 / 9.0;
pub const height: u64 = @intFromFloat(width / aspectRatio);
pub const samples_per_pixel = 50;

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    var r = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
    U.rand = r.random();
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = false }){};
    //defer _ = gpa.detectLeaks();
    const alloc = gpa.allocator();
    const fname = try std.fmt.allocPrint(alloc, "{d}x{d}.ppm", .{ width, height });
    defer alloc.free(fname);
    const picDir = try fs.cwd().openDir("pics", .{});
    const f = try picDir.createFile(fname, .{});
    defer f.close();
    const fw = f.writer();

    var world = try HL.HittableStorage(&[_]type{H.Sphere}).init(alloc);
    var mats = try std.ArrayList(M.Mat).initCapacity(alloc, 500);

    const ground_material = mats.addOneAssumeCapacity();
    ground_material.* = (.{ .Lambertian = .{ .albedo = V.Vec3{ 0.5, 0.5, 0.5 } } });
    try world.append(H.Sphere.init(V.Vec3{ 0, -1000, 0 }, 1000, ground_material));

    for (0..22) |ai| {
        var a: f64 = @floatFromInt(ai);
        a -= 11;
        for (0..22) |bi| {
            var b: f64 = @floatFromInt(bi);
            b -= 11;

            const rad = 0.2;
            const choose_mat = U.randFloat();
            const center = V.Vec3{ a + 0.9 * U.randFloat(), rad, b + 0.9 * U.randFloat() };
            if (V.len(center - V.Vec3{ 4, rad, 0 }) > 0.9) {
                if (choose_mat < 0.8) {
                    // diffuse
                    const albedo = U.randV() * U.randV();
                    const mat = mats.addOneAssumeCapacity();
                    mat.* = (.{ .Lambertian = .{ .albedo = albedo } });
                    try world.append(H.Sphere.init(center, rad, mat));
                } else if (choose_mat < 0.95) {
                    // metal
                    const albedo = U.randVrange(0.5, 1);
                    const fuzz = U.randRange(0, 0.5);
                    const sphere_material = mats.addOneAssumeCapacity();
                    sphere_material.* = (.{ .Metal = .{ .albedo = albedo, .fuzz = V.sc(fuzz) } });
                    try world.append(H.Sphere.init(center, rad, sphere_material));
                } else {
                    // glass
                    const sphere_material = mats.addOneAssumeCapacity();
                    sphere_material.* = (.{ .Dielectric = .{ .refIndex = 1.5 } });
                    try world.append(H.Sphere.init(center, rad, sphere_material));
                }
            }
        }
    }

    const material1 = mats.addOneAssumeCapacity();
    material1.* = .{ .Dielectric = .{ .refIndex = 1.5 } };
    try world.append(H.Sphere.init(V.Vec3{ 0, 1, 0 }, 1.0, material1));
    const material2 = mats.addOneAssumeCapacity();
    material2.* = (.{ .Lambertian = .{ .albedo = V.Vec3{ 0.4, 0.2, 0.1 } } });
    try world.append(H.Sphere.init(V.Vec3{ -4, 1, 0 }, 1.0, material2));
    const material3 = mats.addOneAssumeCapacity();
    material3.* = (.{ .Metal = .{ .albedo = V.Vec3{ 0.7, 0.6, 0.5 }, .fuzz = V.sc(0.0) } });
    try world.append(H.Sphere.init(V.Vec3{ 4, 1, 0 }, 1.0, material3));

    var cam = Cam{
        .width = width,
        .aspectRatio = aspectRatio,
        .samples_per_pixel = samples_per_pixel,
        .max_depth = 50,
        .vfov = 20,
        .lookfrom = V.Vec3{ 13, 2, 3 },
        .lookat = V.Vec3{ 0, 0, 0 },
        .vup = V.Vec3{ 0, 1, 0 },
        .defocus_angle = 0.6,
        .focus_dist = 10.0,
        .alloc = alloc,
    };

    const objs = try world.hittables();
    try stdout.print("redering {d} objs at {d}x{d}", .{ objs.objs.len, height, width });
    try cam.render(fw, objs);
}
