const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const eql = @import("std").mem.eql;

const IO = @import("io").IO;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var sum: u16 = 0;

    while (!io.eof()) {
        const game_word = io.readWord();
        if (!eql(u8, game_word, "Game"))
            @import("std").debug.panic("Unexpected word `{s}`", .{game_word});

        const id = io.readIntUntil(u16, ':');
        _ = io.readWord();

        var is_ok = true;

        while (true) {
            const count = io.readInt(u16);
            var color = io.readWord();
            const has_comma = color[color.len - 1] == ',';
            const has_colon = color[color.len - 1] == ';';
            if (has_comma or has_colon)
                color = color[0 .. color.len - 1];

            if ((eql(u8, color, "red") and count > 12) or
                (eql(u8, color, "green") and count > 13) or
                (eql(u8, color, "blue") and count > 14))
                is_ok = false;

            if (!has_comma and !has_colon)
                break;
        }

        if (is_ok)
            sum += id;
    }

    io.print("{d}", .{sum});
}
