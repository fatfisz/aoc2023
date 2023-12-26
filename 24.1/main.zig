const ArrayList = @import("std").ArrayList;
const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const sign = @import("std").math.sign;

const IO = @import("io").IO;

const Number = i128;

const Hailstone = struct {
    px: Number,
    py: Number,
    pz: Number,
    vx: Number,
    vy: Number,
    vz: Number,
};

const min_bound = 200000000000000;

const max_bound = 400000000000000;

var sum: usize = 0;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var hailstones = ArrayList(Hailstone).init(allocator);
    defer hailstones.deinit();

    while (!io.eof()) {
        const px = io.readInt(Number).?;
        _ = io.readWord();
        const py = io.readInt(Number).?;
        _ = io.readWord();
        const pz = io.readInt(Number).?;
        _ = io.readWord();
        const vx = io.readInt(Number).?;
        _ = io.readWord();
        const vy = io.readInt(Number).?;
        _ = io.readWord();
        const vz = io.readInt(Number).?;

        for (hailstones.items) |hailstone| {
            var lsx = (hailstone.py - py) * hailstone.vx * vx - hailstone.px * hailstone.vy * vx + px * vy * hailstone.vx;
            var rsx = vy * hailstone.vx - hailstone.vy * vx;
            if (rsx < 0) {
                lsx = -lsx;
                rsx = -rsx;
            }

            const x_in_boundary = lsx >= min_bound * rsx and lsx <= max_bound * rsx;

            if (!x_in_boundary)
                continue;

            var lsy = lsx * vy + rsx * (py * vx - px * vy);
            var rsy = rsx * vx;
            if (rsy < 0) {
                lsy = -lsy;
                rsy = -rsy;
            }

            const y_in_boundary = lsy >= min_bound * rsy and lsy <= max_bound * rsy;

            if (!y_in_boundary)
                continue;

            const in_the_future1 = (lsx < rsx * px) == (vx < 0);
            const in_the_future2 = (lsx < rsx * hailstone.px) == (hailstone.vx < 0);

            if (in_the_future1 and in_the_future2)
                sum += 1;
        }

        try hailstones.append(.{
            .px = px,
            .py = py,
            .pz = pz,
            .vx = vx,
            .vy = vy,
            .vz = vz,
        });
    }

    io.print("{d}", .{sum});
}
