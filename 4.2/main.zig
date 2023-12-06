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

    var copies = [_]u32{1} ** 1024;
    var sum: u32 = 0;
    var index: usize = 0;

    _ = io.readWord();
    while (!io.eof()) : (index += 1) {
        _ = io.readWord();

        while (true) {
            const word = io.readWord();

            if (word[0] == '|')
                break;

            try set.put(word, true);
        }

        var cards: u16 = 0;

        while (!io.eof()) {
            const word = io.readWord();

            if (word[0] == 'C')
                break;

            if (set.contains(word))
                cards += 1;
        }

        while (cards > 0) : (cards -= 1)
            copies[index + cards] += copies[index];

        sum += copies[index];

        set.clearAndFree();
    }

    io.print("{d}", .{sum});
}
