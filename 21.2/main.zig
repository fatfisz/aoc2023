const ArrayList = @import("std").ArrayList;
const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;

const IO = @import("io").IO;

const Point = struct {
    x: usize,
    y: usize,
};

const max_size = 4096;

const size_mul = 31;

const target_steps = 26501365;

const initial_step_limit = 2000;

const cycle_limit = 16;

var visited_buf = [_][max_size]bool{
    [_]bool{false} ** max_size,
} ** max_size;

var point_counts_buf = [_]usize{ 1, 0 };

var point_counts_after_steps_buf: [initial_step_limit]usize = undefined;

var point_counts_after_cycles_buf: [32]usize = undefined;
var point_counts_after_cycles_len: usize = 0;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var point_queue = ArrayList(Point).init(allocator);
    defer point_queue.deinit();

    var width: usize = 0;
    var height: usize = 0;
    var start_x: usize = 0;
    var start_y: usize = 0;
    while (!io.eof()) : (height += 1) {
        const line = io.readLine();
        if (width == 0)
            width = line.len;

        for (0..width) |x| {
            switch (line[x]) {
                'S' => {
                    start_x = x;
                    start_y = height;
                },
                '#' => visited_buf[height][x] = true,
                else => {},
            }
        }
    }

    for (0..height) |y|
        for (0..width) |x|
            if (visited_buf[y][x])
                for (0..size_mul) |yy|
                    for (0..size_mul) |xx| {
                        visited_buf[y + yy * height][x + xx * width] = true;
                    };

    start_x += size_mul / 2 * width;
    start_y += size_mul / 2 * height;
    try point_queue.append(.{ .x = start_x, .y = start_y });
    visited_buf[point_queue.items[0].y][point_queue.items[0].x] = true;

    var step_count: usize = 0;
    while (step_count < initial_step_limit and
        !visited_buf[start_y][start_x - width] and
        !visited_buf[start_y][start_x + width] and
        !visited_buf[start_y - height][start_x] and
        !visited_buf[start_y + height][start_x])
    {
        step_count += 1;
        point_counts_buf[step_count % 2] += try step(&point_queue, width, height);
        point_counts_after_steps_buf[step_count] = point_counts_buf[step_count % 2];
    }

    if (step_count == initial_step_limit) {
        // @import("std").debug.panic("The step limit for the initial phase was reached", .{});
        io.print("???", .{});
        return;
    }

    if (!visited_buf[start_y][start_x - width] or
        !visited_buf[start_y][start_x + width] or
        !visited_buf[start_y - height][start_x] or
        !visited_buf[start_y + height][start_x])
    {
        // @import("std").debug.panic(
        //     "Neighboring centers were not all reached at the same time, I don't know what to do 😵",
        //     .{},
        // );
        io.print("???", .{});
        return;
    }

    const cycle_length = step_count;
    const probe_step = target_steps % cycle_length;
    const target_cycles = target_steps / cycle_length;
    point_counts_after_cycles_buf[0] = point_counts_after_steps_buf[probe_step];
    point_counts_after_cycles_len += 1;

    const last_cycle_index = for (0..cycle_limit) |cycle_index| {
        for (0..cycle_length) |step_index| {
            if (step_index == probe_step) {
                point_counts_after_cycles_buf[point_counts_after_cycles_len] = point_counts_buf[step_count % 2];
                point_counts_after_cycles_len += 1;
            }
            step_count += 1;
            point_counts_buf[step_count % 2] += try step(&point_queue, width, height);
        }

        if (cycle_index > 2 and getDiffDiff(cycle_index) == getDiffDiff(cycle_index - 1))
            break cycle_index;
    } else unreachable;

    const result =
        point_counts_after_cycles_buf[0] +
        target_cycles * (point_counts_after_cycles_buf[1] - point_counts_after_cycles_buf[0]) +
        target_cycles * (target_cycles - 1) / 2 * getDiffDiff(last_cycle_index);

    io.print("{d}", .{result});
}

fn step(point_queue: *ArrayList(Point), width: usize, height: usize) !usize {
    var new_point_count: usize = 0;

    const current_points = try point_queue.toOwnedSlice();
    defer point_queue.allocator.free(current_points);

    for (current_points) |point| {
        if (point.x > 0 and !visited_buf[point.y][point.x - 1]) {
            visited_buf[point.y][point.x - 1] = true;
            try point_queue.append(.{ .x = point.x - 1, .y = point.y });
            new_point_count += 1;
        }
        if (point.x < width * size_mul - 1 and !visited_buf[point.y][point.x + 1]) {
            visited_buf[point.y][point.x + 1] = true;
            try point_queue.append(.{ .x = point.x + 1, .y = point.y });
            new_point_count += 1;
        }
        if (point.y > 0 and !visited_buf[point.y - 1][point.x]) {
            visited_buf[point.y - 1][point.x] = true;
            try point_queue.append(.{ .x = point.x, .y = point.y - 1 });
            new_point_count += 1;
        }
        if (point.y < height * size_mul - 1 and !visited_buf[point.y + 1][point.x]) {
            visited_buf[point.y + 1][point.x] = true;
            try point_queue.append(.{ .x = point.x, .y = point.y + 1 });
            new_point_count += 1;
        }
    }

    return new_point_count;
}

fn getDiffDiff(index: usize) u64 {
    return @as(u64, point_counts_after_cycles_buf[index]) +
        point_counts_after_cycles_buf[index - 2] -
        point_counts_after_cycles_buf[index - 1] * 2;
}
