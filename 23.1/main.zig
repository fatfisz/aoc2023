const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const sleep = @import("std").time.sleep;

const IO = @import("io").IO;

const Index = u8;

const PointWithDirection = struct {
    x: Index,
    y: Index,
    direction: Direction,
};

const Direction = enum { up, right, down, left, none };

const Terrain = enum { path, forest, up_slope, right_slope, down_slope, left_slope };

const max_size = 256;

var map_buf: [max_size][max_size]Terrain = undefined;

var width: usize = 0;

var height: usize = 0;

var stack_buf: [max_size * max_size]PointWithDirection = undefined;

var stack_len: usize = 0;

var on_stack = [_][max_size]bool{
    [_]bool{false} ** max_size,
} ** max_size;

var max_path_len: usize = 0;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    while (!io.eof()) : (height += 1) {
        const line = io.readLine();

        if (width == 0)
            width = line.len;

        for (line, 0..) |char, x|
            map_buf[height][x] = switch (char) {
                '.' => .path,
                '#' => .forest,
                '^' => .up_slope,
                '>' => .right_slope,
                'v' => .down_slope,
                '<' => .left_slope,
                else => unreachable,
            };
    }

    pushIfNotOnStack(1, 0, .up);

    while (stack_len > 0) {
        const point = &stack_buf[stack_len - 1];
        const tile = map_buf[point.y][point.x];

        switch (point.direction) {
            .up => {
                if ((tile == .path or tile == .up_slope) and
                    point.y > 0 and
                    map_buf[point.y - 1][point.x] != .forest and
                    map_buf[point.y - 1][point.x] != .down_slope)
                {
                    pushIfNotOnStack(point.x, point.y - 1, .up);
                }
                point.direction = .right;
            },
            .right => {
                if ((tile == .path or tile == .right_slope) and
                    point.x < width - 1 and
                    map_buf[point.y][point.x + 1] != .forest and
                    map_buf[point.y][point.x + 1] != .left_slope)
                {
                    pushIfNotOnStack(point.x + 1, point.y, .up);
                }
                point.direction = .down;
            },
            .down => {
                if ((tile == .path or tile == .down_slope) and
                    point.y < height - 1 and
                    map_buf[point.y + 1][point.x] != .forest and
                    map_buf[point.y + 1][point.x] != .up_slope)
                {
                    pushIfNotOnStack(point.x, point.y + 1, .up);
                }
                point.direction = .left;
            },
            .left => {
                if ((tile == .path or tile == .left_slope) and
                    point.x > 0 and
                    map_buf[point.y][point.x - 1] != .forest and
                    map_buf[point.y][point.x - 1] != .right_slope)
                {
                    pushIfNotOnStack(point.x - 1, point.y, .up);
                }
                point.direction = .none;
            },
            .none => pop(),
        }
    }

    io.print("{d}", .{max_path_len});
}

fn pushIfNotOnStack(x: Index, y: Index, direction: Direction) void {
    if (on_stack[y][x])
        return;

    if (isFinal(x, y))
        max_path_len = @max(max_path_len, stack_len);

    stack_buf[stack_len] = .{
        .x = x,
        .y = y,
        .direction = direction,
    };
    stack_len += 1;
    on_stack[y][x] = true;
}

fn pop() void {
    stack_len -= 1;
    const point = stack_buf[stack_len];
    on_stack[point.y][point.x] = false;
}

fn isFinal(x: Index, y: Index) bool {
    return x == width - 2 and y == height - 1;
}
