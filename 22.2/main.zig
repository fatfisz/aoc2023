const ArrayList = @import("std").ArrayList;
const ArenaAllocator = @import("std").heap.ArenaAllocator;
const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const sort = @import("std").mem.sort;

const IO = @import("io").IO;

const Index = u16;

const Brick = struct {
    min_x: Index,
    max_x: Index,
    min_y: Index,
    max_y: Index,
    min_z: Index,
    max_z: Index,
    supporter_count: Index,
    supportees: ArrayList(Index),
};

const max_bricks = 2048;

const max_size = 512;

var bricks_buf: [max_bricks]Brick = undefined;
var bricks_len: usize = 0;

var height_map = [_][max_size]Index{
    [_]Index{0} ** max_size,
} ** max_size;

var brick_map = [_][max_size]Index{
    [_]Index{0} ** max_size,
} ** max_size;

var bfs_deque: [max_bricks]Index = undefined;

var supporter_count_buf: [max_bricks]Index = undefined;

var falling_sum: usize = 0;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var arena = ArenaAllocator.init(allocator);
    const arena_allocator = arena.allocator();
    defer arena.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    while (!io.eof()) : (bricks_len += 1) {
        const x1 = io.readInt(Index).?;
        _ = io.readChar();
        const y1 = io.readInt(Index).?;
        _ = io.readChar();
        const z1 = io.readInt(Index).?;
        _ = io.readChar();
        const x2 = io.readInt(Index).?;
        _ = io.readChar();
        const y2 = io.readInt(Index).?;
        _ = io.readChar();
        const z2 = io.readInt(Index).?;

        bricks_buf[bricks_len] = .{
            .min_x = @min(x1, x2),
            .max_x = @max(x1, x2),
            .min_y = @min(y1, y2),
            .max_y = @max(y1, y2),
            .min_z = @min(z1, z2),
            .max_z = @max(z1, z2),
            .supporter_count = 0,
            .supportees = ArrayList(Index).init(arena_allocator),
        };
    }
    const bricks = bricks_buf[0..bricks_len];
    sort(Brick, bricks, {}, lessThan);

    for (bricks, 1..) |*brick, index| {
        var max_height: Index = 0;
        for (brick.min_y..brick.max_y + 1) |y|
            for (brick.min_x..brick.max_x + 1) |x|
                if (height_map[y][x] > max_height) {
                    max_height = height_map[y][x];
                };

        var last_supporter: Index = 0;
        for (brick.min_y..brick.max_y + 1) |y|
            for (brick.min_x..brick.max_x + 1) |x| {
                if (height_map[y][x] == max_height and brick_map[y][x] != last_supporter) {
                    last_supporter = brick_map[y][x];
                    brick.supporter_count += 1;
                    try bricks[last_supporter - 1].supportees.append(@truncate(index - 1));
                }
                height_map[y][x] = max_height + brick.max_z + 1 - brick.min_z;
                brick_map[y][x] = @truncate(index);
            };
    }

    for (0..bricks.len) |index| {
        var bfs_deque_index: usize = 0;
        var bfs_deque_len: usize = 1;
        bfs_deque[0] = @truncate(index);
        @memset(supporter_count_buf[0..bricks_len], 0);

        while (bfs_deque_index < bfs_deque_len) : (bfs_deque_index += 1) {
            const brick_index = bfs_deque[bfs_deque_index];
            for (bricks[brick_index].supportees.items) |supportee| {
                supporter_count_buf[supportee] += 1;
                if (supporter_count_buf[supportee] == bricks[supportee].supporter_count) {
                    falling_sum += 1;
                    bfs_deque[bfs_deque_len] = supportee;
                    bfs_deque_len += 1;
                }
            }
        }
    }

    io.print("{d}", .{falling_sum});
}

fn lessThan(_: void, lhs: Brick, rhs: Brick) bool {
    if (lhs.min_z < rhs.min_z) return true;
    if (lhs.min_z > rhs.min_z) return false;
    if (lhs.min_y < rhs.min_y) return true;
    if (lhs.min_y > rhs.min_y) return false;
    return lhs.min_x < rhs.min_x;
}
