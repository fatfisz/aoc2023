const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const endsWith = @import("std").mem.endsWith;
const startsWith = @import("std").mem.startsWith;

const IO = @import("io").IO;

const digits = "0123456789";

const spelled_digits = [_][]const u8{
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
};

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var sum: u16 = 0;

    while (!io.eof()) {
        const line = io.readLine();

        const first = blk: {
            var index: usize = 0;
            while (index < line.len) : (index += 1) {
                inline for (digits) |digit|
                    if (line[index] == digit)
                        break :blk line[index] - '0';
                inline for (spelled_digits, 0..) |digit, digit_index|
                    if (startsWith(u8, line[index..], digit))
                        break :blk @as(u16, @truncate(digit_index)) + 1;
            } else @import("std").debug.panic("Did not find a digit in line `{s}`\n", .{line});
        };

        const last = blk: {
            var index: usize = line.len - 1;
            while (index >= 0) : (index -= 1) {
                inline for (digits) |digit|
                    if (line[index] == digit)
                        break :blk line[index] - '0';
                inline for (spelled_digits, 0..) |digit, digit_index|
                    if (endsWith(u8, line[0 .. index + 1], digit))
                        break :blk @as(u16, @truncate(digit_index)) + 1;
            } else @import("std").debug.panic("Did not find a digit in line `{s}`\n", .{line});
        };

        const number = first * 10 + last;
        sum += number;
    }

    io.print("{d}", .{sum});
}
