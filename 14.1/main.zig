const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;

const IO = @import("io").IO;

const Number = u32;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var load: Number = 0;
    var stop_buf = [_]Number{0} ** 1024;
    var rolling_stone_count: Number = 0;
    var height: Number = 0;

    while (!io.eof()) : (height += 1) {
        load += rolling_stone_count;

        const line = io.readLine();

        for (line, 0..) |char, index| {
            switch (char) {
                'O' => {
                    load += height + 1 - stop_buf[index];
                    stop_buf[index] += 1;
                    rolling_stone_count += 1;
                },
                '#' => {
                    stop_buf[index] = height + 1;
                },
                else => {},
            }
        }
    }

    io.print("{d}", .{load});
}
