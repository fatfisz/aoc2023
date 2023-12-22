const ArrayList = @import("std").ArrayList;
const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;

const IO = @import("io").IO;

const Point = struct {
    x: usize,
    y: usize,
};

const max_size = 256;

const total_steps = 64;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var point_queue = ArrayList(Point).init(allocator);
    defer point_queue.deinit();

    var visited_buf = [_][max_size]bool{
        [_]bool{false} ** max_size,
    } ** max_size;
    var width: usize = 0;
    var height: usize = 0;
    while (!io.eof()) : (height += 1) {
        const line = io.readLine();
        if (width == 0)
            width = line.len;

        for (0..width) |x| {
            switch (line[x]) {
                'S' => {
                    visited_buf[height][x] = true;
                    try point_queue.append(.{ .x = x, .y = height });
                },
                '#' => visited_buf[height][x] = true,
                else => {},
            }
        }
    }

    var sums_buf = [_]usize{ 1, 0 };

    for (1..total_steps + 1) |step| {
        const current_points = try point_queue.toOwnedSlice();
        defer allocator.free(current_points);

        for (current_points) |point| {
            if (point.x > 0 and !visited_buf[point.y][point.x - 1]) {
                visited_buf[point.y][point.x - 1] = true;
                try point_queue.append(.{ .x = point.x - 1, .y = point.y });
                sums_buf[step % 2] += 1;
            }
            if (point.x < width - 1 and !visited_buf[point.y][point.x + 1]) {
                visited_buf[point.y][point.x + 1] = true;
                try point_queue.append(.{ .x = point.x + 1, .y = point.y });
                sums_buf[step % 2] += 1;
            }
            if (point.y > 0 and !visited_buf[point.y - 1][point.x]) {
                visited_buf[point.y - 1][point.x] = true;
                try point_queue.append(.{ .x = point.x, .y = point.y - 1 });
                sums_buf[step % 2] += 1;
            }
            if (point.y < height - 1 and !visited_buf[point.y + 1][point.x]) {
                visited_buf[point.y + 1][point.x] = true;
                try point_queue.append(.{ .x = point.x, .y = point.y + 1 });
                sums_buf[step % 2] += 1;
            }
        }
    }

    io.print("{d}", .{sums_buf[total_steps % 2]});
}
