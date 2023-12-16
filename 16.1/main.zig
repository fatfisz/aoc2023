const ArrayList = @import("std").ArrayList;
const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;

const IO = @import("io").IO;

const Number = u32;

const Index = u8;

const max_size = 128;

const Touch = packed struct {
    left: bool = false,
    right: bool = false,
    top: bool = false,
    bottom: bool = false,
};

const Direction = enum { left, right, top, bottom };

const Beam = struct {
    x: Index,
    y: Index,
    direction: Direction,
};

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var cave_buf: [max_size][]const u8 = undefined;
    var height: usize = 0;
    while (!io.eof()) : (height += 1)
        cave_buf[height] = io.readLine();
    const cave = cave_buf[0..height];
    const width = cave[0].len;

    var queue = ArrayList(Beam).init(allocator);
    defer queue.deinit();

    var touch = [_][max_size]Touch{[_]Touch{.{}} ** max_size} ** max_size;

    try queue.append(.{ .x = 0, .y = 0, .direction = .right });
    while (queue.popOrNull()) |beam| {
        setTouch(&touch[beam.y][beam.x], beam.direction);
        if (getNextBeam(width, height, cave[beam.y][beam.x], beam)) |next_beam|
            if (!getTouch(touch[next_beam.y][next_beam.x], next_beam.direction))
                try queue.append(next_beam);
        if (getNextBeamAlt(width, height, cave[beam.y][beam.x], beam)) |next_beam|
            if (!getTouch(touch[next_beam.y][next_beam.x], next_beam.direction))
                try queue.append(next_beam);
    }

    var sum: Number = 0;
    for (0..height) |y|
        for (0..width) |x|
            if (touch[y][x].left or touch[y][x].right or touch[y][x].top or touch[y][x].bottom) {
                sum += 1;
            };

    io.print("{d}", .{sum});
}

fn getTouch(touch: Touch, direction: Direction) bool {
    return switch (direction) {
        .top => touch.top,
        .right => touch.right,
        .bottom => touch.bottom,
        .left => touch.left,
    };
}

fn setTouch(touch: *Touch, direction: Direction) void {
    switch (direction) {
        .top => touch.top = true,
        .right => touch.right = true,
        .bottom => touch.bottom = true,
        .left => touch.left = true,
    }
}

fn getNextBeam(width: usize, height: usize, cave_point: u8, beam: Beam) ?Beam {
    if (cave_point == '.' and beam.direction == .left or
        cave_point == '/' and beam.direction == .bottom or
        cave_point == '\\' and beam.direction == .top or
        cave_point == '-' and beam.direction != .right)
        return if (beam.x > 0) .{ .x = beam.x - 1, .y = beam.y, .direction = .left } else null;

    if (cave_point == '.' and beam.direction == .right or
        cave_point == '/' and beam.direction == .top or
        cave_point == '\\' and beam.direction == .bottom or
        cave_point == '-' and beam.direction == .right)
        return if (beam.x < width - 1) .{ .x = beam.x + 1, .y = beam.y, .direction = .right } else null;

    if (cave_point == '.' and beam.direction == .top or
        cave_point == '/' and beam.direction == .right or
        cave_point == '\\' and beam.direction == .left or
        cave_point == '|' and beam.direction != .bottom)
        return if (beam.y > 0) .{ .x = beam.x, .y = beam.y - 1, .direction = .top } else null;

    if (cave_point == '.' and beam.direction == .bottom or
        cave_point == '/' and beam.direction == .left or
        cave_point == '\\' and beam.direction == .right or
        cave_point == '|' and beam.direction == .bottom)
        return if (beam.y < height - 1) .{ .x = beam.x, .y = beam.y + 1, .direction = .bottom } else null;

    unreachable;
}

fn getNextBeamAlt(width: usize, height: usize, cave_point: u8, beam: Beam) ?Beam {
    if (cave_point == '|' and (beam.direction == .left or beam.direction == .right))
        return if (beam.y < height - 1) .{ .x = beam.x, .y = beam.y + 1, .direction = .bottom } else null;

    if (cave_point == '-' and (beam.direction == .top or beam.direction == .bottom))
        return if (beam.x < width - 1) .{ .x = beam.x + 1, .y = beam.y, .direction = .right } else null;

    return null;
}
