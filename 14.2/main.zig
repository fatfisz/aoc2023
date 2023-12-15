const AutoHashMap = @import("std").AutoHashMap;
const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const Log2Int = @import("std").math.Log2Int;
const Int = @import("std").meta.Int;

const IO = @import("io").IO;

const Number = u32;

const Index = u7;

const Cell = union(enum) {
    nothing,
    dist: Index,
    value: struct {
        value: Index = 0,
        len: Index = 1,
    },
};

const max_size = 128;

const Hash = Int(.unsigned, max_size * max_size);

const HashShift = Log2Int(Hash);

const Point = struct {
    x: Index,
    y: Index,
};

const cycles = 1_000_000_000;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var vert_buf: [max_size][max_size]Cell = undefined;
    var horz_buf: [max_size][max_size]Cell = undefined;
    var width: Index = 0;
    var height: Index = 0;
    var rolling_stones_buf: [2048]Point = undefined;
    var rolling_stones_len: usize = 0;

    var first_hash_cycle = AutoHashMap(Hash, usize).init(allocator);
    defer first_hash_cycle.deinit();

    var cycle_hash = AutoHashMap(usize, Hash).init(allocator);
    defer cycle_hash.deinit();

    while (!io.eof()) : (height += 1) {
        const line = io.readLine();
        if (width == 0)
            width = @truncate(line.len);

        for (line, 0..) |char, index| {
            if (char == '#') {
                vert_buf[index][height] = .nothing;
                horz_buf[height][index] = .nothing;
                continue;
            }

            vert_buf[index][height] = if (height > 0)
                switch (vert_buf[index][height - 1]) {
                    .nothing => .{ .value = .{} },
                    .dist => |dist| .{ .dist = dist + 1 },
                    .value => .{ .dist = 1 },
                }
            else
                .{ .value = .{} };
            if (vert_buf[index][height] == .dist)
                vert_buf[index][height - vert_buf[index][height].dist].value.len += 1;

            horz_buf[height][index] = if (index > 0)
                switch (horz_buf[height][index - 1]) {
                    .nothing => .{ .value = .{} },
                    .dist => |dist| .{ .dist = dist + 1 },
                    .value => .{ .dist = 1 },
                }
            else
                .{ .value = .{} };
            if (horz_buf[height][index] == .dist)
                horz_buf[height][index - horz_buf[height][index].dist].value.len += 1;

            if (char == 'O') {
                horz_buf[height][getValueIndex(&horz_buf[height], @truncate(index))].value.value += 1;

                rolling_stones_buf[rolling_stones_len] = .{
                    .x = @truncate(index),
                    .y = @truncate(height),
                };
                rolling_stones_len += 1;
            }
        }
    }

    var rolling_stones = rolling_stones_buf[0..rolling_stones_len];
    {
        const hash = getHash(rolling_stones, width);
        try first_hash_cycle.put(hash, 0);
        try cycle_hash.put(0, hash);
    }

    const target_hash = blk: {
        for (1..cycles + 1) |cycle| {
            for (rolling_stones) |*stone| {
                horz_buf[stone.y][getValueIndex(&horz_buf[stone.y], stone.x)].value.value = 0;
                const cell_index = getValueIndex(&vert_buf[stone.x], stone.y);
                const cell = &vert_buf[stone.x][cell_index].value;
                stone.y = cell_index + cell.value;
                cell.value += 1;
            }

            for (rolling_stones) |*stone| {
                vert_buf[stone.x][getValueIndex(&vert_buf[stone.x], stone.y)].value.value = 0;
                const cell_index = getValueIndex(&horz_buf[stone.y], stone.x);
                const cell = &horz_buf[stone.y][cell_index].value;
                stone.x = cell_index + cell.value;
                cell.value += 1;
            }

            for (rolling_stones) |*stone| {
                horz_buf[stone.y][getValueIndex(&horz_buf[stone.y], stone.x)].value.value = 0;
                const cell_index = getValueIndex(&vert_buf[stone.x], stone.y);
                const cell = &vert_buf[stone.x][cell_index].value;
                stone.y = cell_index + cell.len - cell.value - 1;
                cell.value += 1;
            }

            for (rolling_stones) |*stone| {
                vert_buf[stone.x][getValueIndex(&vert_buf[stone.x], stone.y)].value.value = 0;
                const cell_index = getValueIndex(&horz_buf[stone.y], stone.x);
                const cell = &horz_buf[stone.y][cell_index].value;
                stone.x = cell_index + cell.len - cell.value - 1;
                cell.value += 1;
            }

            const hash = getHash(rolling_stones, width);
            if (first_hash_cycle.contains(hash)) {
                const first_cycle = first_hash_cycle.get(hash).?;
                const period = cycle - first_cycle;
                const target_cycle = first_cycle + (cycles - cycle) % period;
                break :blk cycle_hash.get(target_cycle).?;
            }

            try first_hash_cycle.put(hash, cycle);
            try cycle_hash.put(cycle, hash);
        }
        unreachable;
    };

    const load = getLoad(target_hash, width, height);
    io.print("{d}", .{load});
}

fn getValueIndex(cells: []Cell, initialIndex: Index) Index {
    return switch (cells[initialIndex]) {
        .dist => |dist| initialIndex - dist,
        else => initialIndex,
    };
}

fn getHash(rolling_stones: []Point, width: Index) Hash {
    var hash: Hash = 0;
    for (rolling_stones) |stone|
        hash |= @as(Hash, 1) << (@as(HashShift, stone.y) * width + @as(HashShift, stone.x));
    return hash;
}

fn getLoad(hash: Hash, width: Index, height: Index) Number {
    var load: Number = 0;
    for (0..height) |y|
        for (0..width) |x|
            if (hash & @as(Hash, 1) << (@as(HashShift, @truncate(y)) * width + @as(HashShift, @truncate(x))) > 0) {
                load += height - @as(Index, @truncate(y));
            };
    return load;
}
