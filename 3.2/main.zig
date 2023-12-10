const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const eql = @import("std").mem.eql;

const IO = @import("io").IO;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var last_line_len: usize = undefined;
    var sum: u32 = 0;
    var gear_buffer = [_]bool{false} ** 1024;
    var prev_buffer: [1024]u16 = undefined;
    var buffer = [_]u16{0} ** 1024;
    var next_buffer = [_]u16{0} ** 1024;
    var prev_slice = prev_buffer[0..];
    var slice = buffer[0..];
    var next_slice = next_buffer[0..];

    while (!io.eof()) {
        const swap_slice = prev_slice;
        prev_slice = slice;
        slice = next_slice;
        next_slice = swap_slice;

        var first_digit_index: ?usize = null;
        const line = io.readLine();
        last_line_len = line.len;

        for (line, 0..) |char, index| {
            if (IO.isDigit(char)) {
                if (first_digit_index == null)
                    first_digit_index = index;
            } else {
                maybeSaveNumber(line, next_slice, index, first_digit_index);
                first_digit_index = null;
                next_slice[index] = 0;
            }
        }
        maybeSaveNumber(line, next_slice, line.len, first_digit_index);

        processLine(line.len, &sum, &gear_buffer, prev_slice, slice, next_slice);

        for (line, 0..) |char, index|
            gear_buffer[index] = char == '*';
    }

    const swap_slice = prev_slice;
    prev_slice = slice;
    slice = next_slice;
    next_slice = swap_slice;
    @memset(next_slice, 0);

    processLine(last_line_len, &sum, &gear_buffer, prev_slice, slice, next_slice);

    io.print("{d}", .{sum});
}

fn processLine(
    line_len: usize,
    sum: *u32,
    gear_buffer: []bool,
    prev_slice: []u16,
    slice: []u16,
    next_slice: []u16,
) void {
    for (0..line_len) |index| {
        var ratio: u32 = 1;
        var count: usize = 0;
        if (gear_buffer[index]) gear: {
            if (index > 0 and slice[index - 1] > 0) {
                count += 1;
                ratio *= slice[index - 1];
            }
            if (index < line_len - 1 and slice[index + 1] > 0) {
                count += 1;
                ratio *= slice[index + 1];
            }
            if (prev_slice[index] > 0) {
                count += 1;
                if (count > 2) break :gear;
                ratio *= prev_slice[index];
            } else {
                if (index > 0 and prev_slice[index - 1] > 0) {
                    count += 1;
                    if (count > 2) break :gear;
                    ratio *= prev_slice[index - 1];
                }
                if (index < line_len - 1 and prev_slice[index + 1] > 0) {
                    count += 1;
                    if (count > 2) break :gear;
                    ratio *= prev_slice[index + 1];
                }
            }
            if (next_slice[index] > 0) {
                count += 1;
                if (count > 2) break :gear;
                ratio *= next_slice[index];
            } else {
                if (index > 0 and next_slice[index - 1] > 0) {
                    count += 1;
                    if (count > 2) break :gear;
                    ratio *= next_slice[index - 1];
                }
                if (index < line_len - 1 and next_slice[index + 1] > 0) {
                    count += 1;
                    if (count > 2) break :gear;
                    ratio *= next_slice[index + 1];
                }
            }
        }

        if (count == 2)
            sum.* += ratio;
    }
}

fn maybeSaveNumber(line: []const u8, next_slice: []u16, index: usize, first_digit_index: ?usize) void {
    if (first_digit_index) |fdi| {
        const number = IO.asInt(u16, line[fdi..index]).?;

        for (fdi..index) |slice_index|
            next_slice[slice_index] = number;
    }
}
