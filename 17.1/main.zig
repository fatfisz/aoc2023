const EnumArray = @import("std").EnumArray;
const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const maxInt = @import("std").math.maxInt;
const order = @import("std").math.order;
const Order = @import("std").math.Order;
const PriorityQueue = @import("std").PriorityQueue;

const IO = @import("io").IO;

const Number = u32;

const Index = u8;

const max_size = 255;

const Direction = enum { horizontal, vertical };

fn DirectionArray(comptime T: type) type {
    return EnumArray(Direction, T);
}

const Point = struct {
    x: Index,
    y: Index,
};

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var heat_loss_buf: [max_size][max_size]u8 = undefined;
    var width: usize = 0;
    var height: usize = 0;
    while (!io.eof()) : (height += 1) {
        const line = io.readLine();
        if (width == 0)
            width = line.len;
        for (0..width) |x|
            heat_loss_buf[height][x] = line[x] - '0';
    }

    var min_buf = [_][max_size]DirectionArray(Number){
        [_]DirectionArray(Number){
            DirectionArray(Number).initFill(maxInt(Number)),
        } ** max_size,
    } ** max_size;
    min_buf[0][0] = DirectionArray(Number).initFill(0);

    var queue = PointQueue.init(allocator, .{ .min_buf = &min_buf });
    defer queue.deinit();
    try queue.add(.{ .x = 0, .y = 0 });

    while (queue.removeOrNull()) |point| {
        relax(heat_loss_buf, &min_buf, &queue, point, @truncate(width), true, true);
        relax(heat_loss_buf, &min_buf, &queue, point, @truncate(height), true, false);
        relax(heat_loss_buf, &min_buf, &queue, point, @truncate(width), false, true);
        relax(heat_loss_buf, &min_buf, &queue, point, @truncate(height), false, false);
    }

    io.print("{d}", .{getMinFromAllDirections(min_buf[height - 1][width - 1])});
}

const PointQueue = PriorityQueue(Point, PointQueueContext, PointQueueContext.lessThan);

const PointQueueContext = struct {
    min_buf: *[max_size][max_size]DirectionArray(Number),

    fn lessThan(self: PointQueueContext, a: Point, b: Point) Order {
        return order(
            getMinFromAllDirections(self.min_buf[a.y][a.x]),
            getMinFromAllDirections(self.min_buf[b.y][b.x]),
        );
    }
};

const max_distance = 3;

fn relax(
    heat_loss_buf: [max_size][max_size]u8,
    min_buf: *[max_size][max_size]DirectionArray(Number),
    queue: *PointQueue,
    base_point: Point,
    max: Index,
    asc: bool,
    comptime horizontal: bool,
) void {
    const direction = if (horizontal) .horizontal else .vertical;
    const other_direction = if (horizontal) .vertical else .horizontal;
    var sum = min_buf[base_point.y][base_point.x].get(other_direction);
    if (sum == maxInt(Number)) return;

    var point = base_point;
    const field_name = if (horizontal) "x" else "y";
    const field_value = @field(point, field_name);
    const boundary = if (asc) max - field_value else field_value + 1;
    for (1..@min(boundary, max_distance + 1)) |_| {
        if (asc)
            @field(point, field_name) += 1
        else
            @field(point, field_name) -= 1;

        sum += heat_loss_buf[point.y][point.x];

        if (min_buf[point.y][point.x].get(direction) > sum) {
            min_buf[point.y][point.x].set(direction, sum);
            queue.add(point) catch unreachable;
        }
    }
}

fn getMinFromAllDirections(cell: DirectionArray(Number)) Number {
    return @min(cell.get(.horizontal), cell.get(.vertical));
}
