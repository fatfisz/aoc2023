const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const StringHashMap = @import("std").StringHashMap;

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

    _ = io.readWord();
    while (!io.eof()) {
        _ = io.readWord();

        while (true) {
            const word = io.readWord();

            if (word[0] == '|')
                break;

            try set.put(word, true);
        }

        var points: u16 = 0;

        while (!io.eof()) {
            const word = io.readWord();

            if (word[0] == 'C')
                break;

            if (set.contains(word))
                points = if (points == 0) 1 else @shlExact(points, 1);
        }

        sum += points;

        set.clearAndFree();
    }

    io.print("{d}", .{sum});
}
