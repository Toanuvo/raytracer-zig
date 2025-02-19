const std = @import("std");
const V = @import("vector.zig");

pub var rand: std.Random = undefined;

const RandLen = 2 << 10;
var RandBuf: [RandLen]f64 = undefined;

const AI = std.atomic.Value(usize);
var i: AI = AI.init(RandLen);

pub fn randFloat() f64 {
    return rand.float(f64);
}
pub fn _randFloat() f64 {
    if (i >= RandLen) {
        for (&RandBuf) |*v| {
            v.* = rand.float(f64);
        }
        i = 0;
    }
    const v = RandBuf[i];
    i += 1;
    return v;
}

pub fn randRange(min: f64, max: f64) f64 {
    return min + (max - min) * randFloat();
}

pub fn randV() V.Vec3 {
    return V.Vec3{ randFloat(), randFloat(), randFloat() };
}

pub fn randVrange(min: f64, max: f64) V.Vec3 {
    return V.Vec3{ randRange(min, max), randRange(min, max), randRange(min, max) };
}

pub fn randVinUnitDisk() V.Vec3 {
    while (true) {
        const p = V.Vec3{ randRange(-1, 1), randRange(-1, 1), 0 };
        if (V.lensq(p) < 1) {
            return p;
        }
    }
}

pub fn randVinUnitSphere() V.Vec3 {
    while (true) {
        const p = randVrange(-1, 1);
        if (V.lensq(p) < 1) {
            return p;
        }
    }
}

pub fn randVUnit() V.Vec3 {
    return V.unit(randVinUnitSphere());
}

pub fn randVonHemi(norm: V.Vec3) V.Vec3 {
    const v = V.unit(randVinUnitSphere());
    if (V.dot(v, norm) > 0) {
        return v;
    } else {
        return -v;
    }
}
