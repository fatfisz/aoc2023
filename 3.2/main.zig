const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const eql = @import("std").mem.eql;
const swap = @import("std").mem.swap;

const IO = @import("io").IO;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var last_line_len: usize = undefined;
    var sum: u32 = 0;
    var gears_buf = [_]bool{false} ** 1024;
    var buf = [_]u16{0} ** 3072;
    var prev_values = buf[0..][0..1024];
    var values = buf[1024..][0..1024];
    var next_values = buf[2048..][0..1024];

    while (!io.eof()) {
        swap(*[1024]u16, &prev_values, &values);
        swap(*[1024]u16, &values, &next_values);

        var first_digit_index: ?usize = null;
        const line = io.readLine();
        last_line_len = line.len;

        for (line, 0..) |char, index| {
            if (IO.isDigit(char)) {
                if (first_digit_index == null)
                    first_digit_index = index;
            } else {
                maybeSaveNumber(line, next_values, index, first_digit_index);
                first_digit_index = null;
                next_values[index] = 0;
            }
        }
        maybeSaveNumber(line, next_values, line.len, first_digit_index);

        processLine(line.len, &sum, &gears_buf, prev_values, values, next_values);

        for (line, gears_buf[0..line.len]) |char, *gear|
            gear.* = char == '*';
    }

    swap(*[1024]u16, &prev_values, &values);
    swap(*[1024]u16, &values, &next_values);
    @memset(next_values, 0);

    processLine(last_line_len, &sum, &gears_buf, prev_values, values, next_values);

    io.print("{d}", .{sum});
}

fn processLine(
    line_len: usize,
    sum: *u32,
    gears: []bool,
    prev_values: []u16,
    values: []u16,
    next_values: []u16,
) void {
    for (0..line_len) |index| {
        var ratio: u32 = 1;
        var count: usize = 0;
        if (gears[index]) gear: {
            if (index > 0 and values[index - 1] > 0) {
                count += 1;
                ratio *= values[index - 1];
            }
            if (index < line_len - 1 and values[index + 1] > 0) {
                count += 1;
                ratio *= values[index + 1];
            }
            if (prev_values[index] > 0) {
                count += 1;
                if (count > 2) break :gear;
                ratio *= prev_values[index];
            } else {
                if (index > 0 and prev_values[index - 1] > 0) {
                    count += 1;
                    if (count > 2) break :gear;
                    ratio *= prev_values[index - 1];
                }
                if (index < line_len - 1 and prev_values[index + 1] > 0) {
                    count += 1;
                    if (count > 2) break :gear;
                    ratio *= prev_values[index + 1];
                }
            }
            if (next_values[index] > 0) {
                count += 1;
                if (count > 2) break :gear;
                ratio *= next_values[index];
            } else {
                if (index > 0 and next_values[index - 1] > 0) {
                    count += 1;
                    if (count > 2) break :gear;
                    ratio *= next_values[index - 1];
                }
                if (index < line_len - 1 and next_values[index + 1] > 0) {
                    count += 1;
                    if (count > 2) break :gear;
                    ratio *= next_values[index + 1];
                }
            }
        }

        if (count == 2)
            sum.* += ratio;
    }
}

fn maybeSaveNumber(line: []const u8, next_values: []u16, index: usize, first_digit_index: ?usize) void {
    if (first_digit_index) |fdi| {
        const number = IO.asInt(u16, line[fdi..index]).?;

        for (fdi..index) |i|
            next_values[i] = number;
    }
}
