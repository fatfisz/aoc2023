const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const indexOfAny = @import("std").mem.indexOfAny;
const lastIndexOfAny = @import("std").mem.lastIndexOfAny;

const IO = @import("io").IO;

const digits = "0123456789";

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var sum: u16 = 0;

    while (!io.eof()) {
        const line = io.readLine();
        const first_index = indexOfAny(u8, line, digits).?;
        const last_index = lastIndexOfAny(u8, line, digits).?;
        const number = (line[first_index] - '0') * 10 + line[last_index] - '0';
        sum += number;
    }

    io.print("{d}", .{sum});
}
