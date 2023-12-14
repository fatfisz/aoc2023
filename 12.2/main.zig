const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const indexOfScalar = @import("std").mem.indexOfScalar;

const IO = @import("io").IO;

const Number = u64;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var sum: Number = 0;

    while (!io.eof()) {
        const raw_row = io.readWord();
        const row = try allocator.alloc(u8, raw_row.len * 5 + 4);
        defer allocator.free(row);
        for (0..5) |i|
            @memcpy(row[i * (raw_row.len + 1) ..].ptr, raw_row);
        for (1..5) |i|
            row[i * (raw_row.len + 1) - 1] = '?';

        var group_lengths_buf: [1024]Number = undefined;
        var group_lengths_count: usize = 0;
        while (io.readInt(Number)) |group_length| : (group_lengths_count += 1) {
            _ = io.consumeChar(',');
            group_lengths_buf[group_lengths_count] = group_length;
        }
        for (1..5) |i|
            @memcpy(group_lengths_buf[group_lengths_count * i ..].ptr, group_lengths_buf[0..group_lengths_count]);
        var group_lengths = group_lengths_buf[0 .. group_lengths_count * 5];

        var combinations_buf: [2048]Number = undefined;
        var combinations = combinations_buf[0..][0..row.len];
        var prev_combinations = combinations_buf[1024..][0..row.len];
        {
            var first_hash_index = indexOfScalar(u8, row, '#') orelse row.len;
            @memset(combinations[0..first_hash_index], 1);
            @memset(combinations[first_hash_index..], 0);
        }

        var min_index: Number = 0;
        for (group_lengths) |group_length| {
            const swap_combinations = prev_combinations;
            prev_combinations = combinations;
            combinations = swap_combinations;

            var start_index = min_index;
            var period_count = countChar(row[start_index..][0..group_length], '.');

            while (period_count > 0 or start_index + group_length < row.len and row[start_index + group_length] == '#') {
                if (row[start_index] == '.') period_count -= 1;
                if (row[start_index + group_length] == '.') period_count += 1;
                start_index += 1;
            }
            min_index = start_index + group_length + 1;

            @memset(combinations[0 .. start_index + group_length - 1], 0);
            for (start_index..row.len - group_length + 1) |index| {
                const end_index = index + group_length - 1;
                combinations[end_index] = 0;

                if (row[end_index] != '#' and end_index > 0)
                    combinations[end_index] += combinations[end_index - 1];

                if (period_count == 0 and (index == 0 or row[index - 1] != '#'))
                    combinations[end_index] += if (index > 1) prev_combinations[index - 2] else 1;

                if (row[index] == '.') period_count -= 1;
                if (end_index + 1 < row.len and row[end_index + 1] == '.') period_count += 1;
            }
        }

        sum += combinations[combinations.len - 1];
    }

    io.print("{d}", .{sum});
}

fn countChar(string: []const u8, char: u8) Number {
    var count: Number = 0;
    for (string) |c| if (c == char) {
        count += 1;
    };
    return count;
}
