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
    var symbol_buffer = [_]bool{false} ** 1024;
    var prev_buffer: [1024]u16 = undefined;
    var buffer = [_]u16{0} ** 1024;
    var prev_slice = prev_buffer[0..];
    var slice = buffer[0..];

    while (!io.eof()) {
        const swap_slice = prev_slice;
        prev_slice = slice;
        slice = swap_slice;

        var first_digit_index: ?usize = null;
        const line = io.readLine();

        for (line, 0..) |char, index| {
            if (isDigit(char)) {
                if (first_digit_index == null)
                    first_digit_index = index;
            } else {
                maybeSaveNumber(line, slice, index, first_digit_index);
                first_digit_index = null;
                slice[index] = 0;
            }
        }
        maybeSaveNumber(line, slice, line.len, first_digit_index);

        for (line, 0..) |char, index| {
            if (symbol_buffer[index]) {
                if (slice[index] > 0) {
                    sum += slice[index];
                    cleanBoth(slice, index, line.len);
                }

                if (index > 0 and slice[index - 1] > 0) {
                    sum += slice[index - 1];
                    cleanBackward(slice, index - 1);
                }

                if (index < line.len - 1 and slice[index + 1] > 0) {
                    sum += slice[index + 1];
                    cleanForward(slice, index + 1, line.len);
                }
            }

            const is_symbol = !isDigit(char) and char != '.';
            symbol_buffer[index] = is_symbol;

            if (is_symbol) {
                if (index > 0 and slice[index - 1] > 0) {
                    sum += slice[index - 1];
                    cleanBackward(slice, index - 1);
                }

                if (index < line.len - 1 and slice[index + 1] > 0) {
                    sum += slice[index + 1];
                    cleanForward(slice, index + 1, line.len);
                }

                if (prev_slice[index] > 0) {
                    sum += prev_slice[index];
                    cleanBoth(prev_slice, index, line.len);
                }

                if (index > 0 and prev_slice[index - 1] > 0) {
                    sum += prev_slice[index - 1];
                    cleanBackward(prev_slice, index - 1);
                }

                if (index < line.len - 1 and prev_slice[index + 1] > 0) {
                    sum += prev_slice[index + 1];
                    cleanForward(prev_slice, index + 1, line.len);
                }
            }
        }
    }

    io.print("{d}", .{sum});
}

fn maybeSaveNumber(line: []const u8, next_slice: []u16, index: usize, first_digit_index: ?usize) void {
    if (first_digit_index) |fdi| {
        const number = IO.asInt(u16, line[fdi..index]);

        var slice_index = fdi;
        while (slice_index < index) : (slice_index += 1)
            next_slice[slice_index] = number;
    }
}

fn isDigit(char: u8) bool {
    return char >= '0' and char <= '9';
}

fn cleanBackward(slice: []u16, index: usize) void {
    var slice_index = index;
    while (slice_index > 0 and slice[slice_index] > 0) : (slice_index -= 1)
        slice[slice_index] = 0;
    slice[slice_index] = 0;
}

fn cleanForward(slice: []u16, index: usize, len: usize) void {
    var slice_index = index;
    while (slice_index < len and slice[slice_index] > 0) : (slice_index += 1)
        slice[slice_index] = 0;
}

fn cleanBoth(slice: []u16, index: usize, len: usize) void {
    cleanBackward(slice, index);
    cleanForward(slice, index + 1, len);
}
