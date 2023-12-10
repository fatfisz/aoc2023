const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const tokenizeScalar = @import("std").mem.tokenizeScalar;

const IO = @import("io").IO;

const Map = [1024][1024]u8;

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

    var map: Map = undefined;

    const first_line = io.readLine();
    const width = first_line.len;
    @memcpy(map[0][0..width], first_line);

    var height: usize = 1;
    while (!io.eof()) : (height += 1) {
        const line = io.readLine();
        @memcpy(map[height][0..width], line);
    }

    const start = blk: {
        for (0..height) |y| for (0..width) |x|
            if (map[y][x] == 'S')
                break :blk Point{ .x = x, .y = y };
        unreachable;
    };

    var dist: usize = 1;
    var prev_current = start;
    var current = getNext(&map, width, height, start, start);

    while (current.x != start.x or current.y != start.y) : (dist += 1) {
        const next_prev_current = current;
        current = getNext(&map, width, height, current, prev_current);
        prev_current = next_prev_current;
    }
    dist /= 2;

    io.print("{d}", .{dist});
}

fn getNext(map: *Map, width: usize, height: usize, current: Point, prev: Point) Point {
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
