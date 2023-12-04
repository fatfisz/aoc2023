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

    while (!io.eof()) {
        const game_word = io.readWord();
        if (!eql(u8, game_word, "Game"))
            @import("std").debug.panic("Unexpected word `{s}`", .{game_word});

        _ = io.readWord();

        var min_red: u16 = 0;
        var min_green: u16 = 0;
        var min_blue: u16 = 0;

        while (true) {
            const count = io.readInt(u16);
            var color = io.readWord();
            const has_comma = color[color.len - 1] == ',';
            const has_colon = color[color.len - 1] == ';';
            if (has_comma or has_colon)
                color = color[0 .. color.len - 1];

            if (eql(u8, color, "red") and count > min_red)
                min_red = count;
            if (eql(u8, color, "green") and count > min_green)
                min_green = count;
            if (eql(u8, color, "blue") and count > min_blue)
                min_blue = count;

            if (!has_comma and !has_colon)
                break;
        }

        const power: u32 = min_red * min_green * min_blue;
        sum += power;
    }

    io.print("{d}", .{sum});
}
