const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const eql = @import("std").mem.eql;

const IO = @import("io").IO;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var sum: u32 = 0;
    var symbol_buf = [_]bool{false} ** 1024;
    var buf = [_]u16{0} ** 2048;
    var prev_values = buf[0..][0..1024];
    var values = buf[1024..][0..1024];

    while (!io.eof()) {
        const swap_values = prev_values;
        prev_values = values;
        values = swap_values;

        var first_digit_index: ?usize = null;
        const line = io.readLine();

        for (line, 0..) |char, index| {
            if (IO.isDigit(char)) {
                if (first_digit_index == null)
                    first_digit_index = index;
            } else {
                maybeSaveNumber(line, values, index, first_digit_index);
                first_digit_index = null;
                values[index] = 0;
            }
        }
        maybeSaveNumber(line, values, line.len, first_digit_index);

        for (line, 0..) |char, index| {
            if (symbol_buf[index]) {
                if (values[index] > 0) {
                    sum += values[index];
                    cleanBoth(values, index, line.len);
                }

                if (index > 0 and values[index - 1] > 0) {
                    sum += values[index - 1];
                    cleanBackward(values, index - 1);
                }

                if (index < line.len - 1 and values[index + 1] > 0) {
                    sum += values[index + 1];
                    cleanForward(values, index + 1, line.len);
                }
            }

            const is_symbol = !IO.isDigit(char) and char != '.';
            symbol_buf[index] = is_symbol;

            if (is_symbol) {
                if (index > 0 and values[index - 1] > 0) {
                    sum += values[index - 1];
                    cleanBackward(values, index - 1);
                }

                if (index < line.len - 1 and values[index + 1] > 0) {
                    sum += values[index + 1];
                    cleanForward(values, index + 1, line.len);
                }

                if (prev_values[index] > 0) {
                    sum += prev_values[index];
                    cleanBoth(prev_values, index, line.len);
                }

                if (index > 0 and prev_values[index - 1] > 0) {
                    sum += prev_values[index - 1];
                    cleanBackward(prev_values, index - 1);
                }

                if (index < line.len - 1 and prev_values[index + 1] > 0) {
                    sum += prev_values[index + 1];
                    cleanForward(prev_values, index + 1, line.len);
                }
            }
        }
    }

    io.print("{d}", .{sum});
}

fn maybeSaveNumber(line: []const u8, next_values: []u16, index: usize, first_digit_index: ?usize) void {
    if (first_digit_index) |fdi| {
        const number = IO.asInt(u16, line[fdi..index]).?;

        for (fdi..index) |i|
            next_values[i] = number;
    }
}

fn cleanBackward(values: []u16, index: usize) void {
    var i = index;
    while (i > 0 and values[i] > 0) : (i -= 1)
        values[i] = 0;
    values[i] = 0;
}

fn cleanForward(values: []u16, index: usize, len: usize) void {
    var i = index;
    while (i < len and values[i] > 0) : (i += 1)
        values[i] = 0;
}

fn cleanBoth(values: []u16, index: usize, len: usize) void {
    cleanBackward(values, index);
    cleanForward(values, index + 1, len);
}
