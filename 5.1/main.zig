const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const min = @import("std").mem.min;

const IO = @import("io").IO;

const Number = u64;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var touched: [1024]bool = undefined;
    var numbers_buf: [1024]Number = undefined;
    var next_numbers_buf: [1024]Number = undefined;
    var length: u16 = 0;

    _ = io.readWord();
    while (!io.eof()) : (length += 1) {
        const maybe_number = io.readWord();
        if (maybe_number.len == 0) {
            _ = io.readLine();
            break;
        }
        next_numbers_buf[length] = IO.asInt(Number, maybe_number);
    }

    var numbers = numbers_buf[0..length];
    var next_numbers = next_numbers_buf[0..length];

    while (!io.eof()) {
        const swap = numbers;
        numbers = next_numbers;
        next_numbers = swap;
        @memcpy(next_numbers, numbers);
        @memset(touched[0..length], false);

        while (!io.eof()) {
            const maybe_destination = io.readWord();
            if (maybe_destination.len == 0) {
                _ = io.readLine();
                break;
            }

            const destination = IO.asInt(Number, maybe_destination);
            const source = io.readInt(Number);
            const range_length = io.readInt(Number);

            for (numbers, 0..) |number, index|
                if (!touched[index] and number >= source and number < source + range_length) {
                    next_numbers[index] = destination + (number - source);
                    touched[index] = true;
                };
        }
    }

    const min_location = min(Number, next_numbers);
    io.print("{d}", .{min_location});
}