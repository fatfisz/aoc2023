const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const rotate = @import("std").mem.rotate;
const reverse = @import("std").mem.reverse;

const IO = @import("io").IO;

const Number = i64;

const Index = u32;

const Point = struct {
    x: Index,
    y: Index,
};

const offset = 1e7;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var points_buf: [1024]Point = undefined;
    var points_len: usize = 0;
    {
        var x: Index = offset;
        var y: Index = offset;
        while (!io.eof()) : (points_len += 1) {
            _ = io.readWord();
            _ = io.readWord();
            const color = io.readWord();
            const len = IO.asHexInt(Index, color[2..][0..5]).?;
            const direction_symbol = color[7];
            switch (direction_symbol) {
                '2' => x -= len,
                '0' => x += len,
                '3' => y -= len,
                '1' => y += len,
                else => unreachable,
            }
            points_buf[points_len] = .{ .x = x, .y = y };
        }
    }
    const points = points_buf[0..points_len];

    var min_point_index: usize = 0;
    for (points[1..], 1..) |point, index| {
        if (point.y < points[min_point_index].y or
            point.y == points[min_point_index].y and point.x < points[min_point_index].x)
            min_point_index = index;
    }
    if (min_point_index > 0)
        rotate(Point, points, min_point_index);
    if (points[0].y != points[1].y)
        reverse(Point, points[1..]);

    var area: Number = 0;
    for (0..points.len / 2) |index| {
        var start: Number = points[index * 2].x;
        var end: Number = points[index * 2 + 1].x;

        if (index != 0 and points[index * 2 - 1].y < points[index * 2].y)
            start += 1;
        if (index < points.len / 2 - 1 and points[index * 2 + 2].y > points[index * 2 + 1].y)
            end += 1;

        var y_mod: Index = if (start < end) 0 else 1;
        area += (points[index * 2].y + y_mod) * (start - end);
    }

    io.print("{d}", .{area});
}
