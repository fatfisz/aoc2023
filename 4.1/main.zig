const StringHashMap = @import("std").StringHashMap;
const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;

const IO = @import("io").IO;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var set = StringHashMap(bool).init(allocator);
    defer set.deinit();

    var sum: u16 = 0;

    while (!io.eof()) {
        _ = io.readWord();
        _ = io.readWord();

        while (io.peek() != '|') {
            const word = io.readUntil(' ');
            io.skip();

            if (word.len == 0) continue;

            try set.put(word, true);
        }

        io.skip();
        var points: u16 = 0;

        while (!io.eof() and io.peek() != '\n') {
            const word = io.readUntilAny(" \n");
            if (!io.eof() and io.peek() == ' ')
                io.skip();

            if (word.len == 0) continue;

            if (set.contains(word))
                points = if (points == 0) 1 else @shlExact(points, 1);
        }

        if (!io.eof())
            io.skip();

        sum += points;

        set.clearAndFree();
    }

    io.print("{d}", .{sum});
}
