const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;

const IO = @import("io").IO;

const Number = u16;

const Index = u16;

const Direction = enum { left, right, up, down };

const Instruction = struct {
    direction: Direction,
    len: Index,
};

const offset = 512;

const max_size = 1024;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var instructions_buf: [1024]Instruction = undefined;
    var instructions_len: usize = 0;
    var trench_buf = [_][max_size]u8{
        [_]u8{'.'} ** max_size,
    } ** max_size;
    var x_min: Index = offset;
    var y_min: Index = offset;
    var x_max: Index = offset + 1;
    var y_max: Index = offset + 1;
    {
        var x: Index = offset;
        var y: Index = offset;
        while (!io.eof()) : (instructions_len += 1) {
            const direction_symbol = io.readWord();
            const direction: Direction = switch (direction_symbol[0]) {
                'L' => .left,
                'R' => .right,
                'U' => .up,
                'D' => .down,
                else => unreachable,
            };
            const len = io.readInt(Index).?;
            _ = io.readWord();

            instructions_buf[instructions_len] = .{
                .direction = direction,
                .len = len,
            };

            if (instructions_len > 0)
                trench_buf[y][x] = getTurn(instructions_buf[instructions_len - 1].direction, direction);

            switch (direction) {
                .left => {
                    for (1..len) |i| trench_buf[y][x - i] = '-';
                    x -= len;
                },
                .right => {
                    for (1..len) |i| trench_buf[y][x + i] = '-';
                    x += len;
                },
                .up => {
                    for (1..len) |i| trench_buf[y - i][x] = '|';
                    y -= len;
                },
                .down => {
                    for (1..len) |i| trench_buf[y + i][x] = '|';
                    y += len;
                },
            }
            x_min = @min(x_min, x);
            y_min = @min(y_min, y);
            x_max = @max(x_max, x + 1);
            y_max = @max(y_max, y + 1);
        }
        trench_buf[y][x] = getTurn(
            instructions_buf[instructions_len - 1].direction,
            instructions_buf[0].direction,
        );
    }

    var area: usize = 0;
    for (y_min..y_max) |y| {
        var x: usize = x_min;
        var inside = false;
        while (x < x_max) : (x += 1) {
            switch (trench_buf[y][x]) {
                '.' => {
                    if (inside) area += 1;
                },
                '|' => {
                    inside = !inside;
                    area += 1;
                },
                'L', 'F' => |turn_start| {
                    x += 1;
                    area += 2;
                    while (trench_buf[y][x] == '-') : (x += 1)
                        area += 1;

                    const ignore_end: u8 = if (turn_start == 'L') 'J' else '7';
                    if (trench_buf[y][x] != ignore_end)
                        inside = !inside;
                },
                else => unreachable,
            }
        }
    }

    io.print("{d}", .{area});
}

fn getTurn(prev_direction: Direction, direction: Direction) u8 {
    if (prev_direction == .left and direction == .up or
        prev_direction == .down and direction == .right) return 'L';
    if (prev_direction == .right and direction == .down or
        prev_direction == .up and direction == .left) return '7';
    if (prev_direction == .left and direction == .down or
        prev_direction == .up and direction == .right) return 'F';
    if (prev_direction == .right and direction == .up or
        prev_direction == .down and direction == .left) return 'J';
    unreachable;
}
