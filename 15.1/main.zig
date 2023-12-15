const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;

const IO = @import("io").IO;

const Number = u32;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var sum: Number = 0;

    while (!io.eof()) {
        sum += getHash(io.readUntil(','));

        if (!io.eof()) _ = io.readChar();
    }

    io.print("{d}", .{sum});
}

fn getHash(chars: []const u8) u8 {
    var hash: u8 = 0;

    for (chars) |char| {
        hash +%= char;
        hash *%= 17;
    }

    return hash;
}
