const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;

const IO = @import("io").IO;

fn Map(comptime T: type) type {
    return [1024][1024]T;
}

const Point = struct {
    x: usize,
    y: usize,
};

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var map: Map(u8) = undefined;
    var is_loop: Map(bool) = [_][1024]bool{[_]bool{false} ** 1024} ** 1024;

    const first_line = io.readLine();
    const width = first_line.len;
    @memcpy(map[0][0..width], first_line);

    var height: usize = 1;
    while (!io.eof()) : (height += 1) {
        const line = io.readLine();
        @memcpy(map[height][0..width], line);
    }

    const start = blk: {
        for (0..height) |y|
            for (0..width) |x|
                if (map[y][x] == 'S')
                    break :blk Point{ .x = x, .y = y };
        unreachable;
    };
    is_loop[start.y][start.x] = true;

    var prev_current = start;
    var current = getNext(&map, width, height, start, start);
    var second = getNext(&map, width, height, start, current);

    map[start.y][start.x] = if (current.x < start.x)
        if (second.x > start.x) '-' else if (second.y < start.y) 'J' else '7'
    else if (current.x > start.x)
        if (second.y < start.y) 'L' else 'F'
    else
        '|';

    while (current.x != start.x or current.y != start.y) {
        is_loop[current.y][current.x] = true;
        const next_prev_current = current;
        current = getNext(&map, width, height, current, prev_current);
        prev_current = next_prev_current;
    }
    is_loop[current.y][current.x] = true;

    var area: usize = 0;

    for (0..height) |y| {
        var x: usize = 0;
        var inside = false;
        while (x < width) : (x += 1) {
            if (!is_loop[y][x]) {
                if (inside)
                    area += 1;
            } else switch (map[y][x]) {
                '|' => inside = !inside,
                'L', 'F' => |turn_start| {
                    x += 1;
                    while (map[y][x] == '-') : (x += 1) {}

                    const ignore_end: u8 = if (turn_start == 'L') 'J' else '7';
                    if (map[y][x] != ignore_end)
                        inside = !inside;
                },
                else => unreachable,
            }
        }
    }

    io.print("{d}", .{area});
}

fn getNext(map: *Map(u8), width: usize, height: usize, current: Point, prev: Point) Point {
    if (connectsToLeft(map[current.y][current.x]) and
        current.x > 0 and
        prev.x != current.x - 1 and
        connectsToRight(map[current.y][current.x - 1]))
        return .{ .x = current.x - 1, .y = current.y };

    if (connectsToRight(map[current.y][current.x]) and
        current.x < width - 1 and
        prev.x != current.x + 1 and
        connectsToLeft(map[current.y][current.x + 1]))
        return .{ .x = current.x + 1, .y = current.y };

    if (connectsToTop(map[current.y][current.x]) and
        current.y > 0 and
        prev.y != current.y - 1 and
        connectsToBottom(map[current.y - 1][current.x]))
        return .{ .x = current.x, .y = current.y - 1 };

    if (connectsToBottom(map[current.y][current.x]) and
        current.y < height - 1 and
        prev.y != current.y + 1 and
        connectsToTop(map[current.y + 1][current.x]))
        return .{ .x = current.x, .y = current.y + 1 };

    unreachable;
}

// | is a vertical pipe connecting north and south.
// - is a horizontal pipe connecting east and west.
// L is a 90-degree bend connecting north and east.
// J is a 90-degree bend connecting north and west.
// 7 is a 90-degree bend connecting south and west.
// F is a 90-degree bend connecting south and east.

inline fn connectsToRight(char: u8) bool {
    return char == 'S' or char == '-' or char == 'L' or char == 'F';
}

inline fn connectsToLeft(char: u8) bool {
    return char == 'S' or char == '-' or char == 'J' or char == '7';
}

inline fn connectsToBottom(char: u8) bool {
    return char == 'S' or char == '|' or char == '7' or char == 'F';
}

inline fn connectsToTop(char: u8) bool {
    return char == 'S' or char == '|' or char == 'L' or char == 'J';
}
