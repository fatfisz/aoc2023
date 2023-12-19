const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const Log2Int = @import("std").math.Log2Int;
const Int = @import("std").meta.Int;

const IO = @import("io").IO;

const Number = u32;

const Hash = Int(.unsigned, 32);

const HashShift = Log2Int(Hash);

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var sum: Number = 0;

    while (!io.eof()) {
        var row_hashes_buf: [1024]Hash = undefined;
        var column_hashes_buf: [1024]Hash = undefined;
        var width: usize = 0;
        var height: usize = 0;

        while (!io.eof()) : (height += 1) {
            const line = io.readLine();
            if (line.len == 0)
                break;

            if (width == 0) {
                width = line.len;
                @memset(column_hashes_buf[0..width], 0);
            }
            row_hashes_buf[height] = 0;

            for (line, 0..) |char, index| if (char == '#') {
                row_hashes_buf[height] |= @as(Hash, 1) << @as(HashShift, @truncate(index));
                column_hashes_buf[index] |= @as(Hash, 1) << @as(HashShift, @truncate(height));
            };
        }

        const row_hashes = row_hashes_buf[0..height];
        const column_hashes = column_hashes_buf[0..width];

        if (findReflection(row_hashes)) |rows|
            sum += @as(Number, @truncate(rows)) * 100
        else if (findReflection(column_hashes)) |columns|
            sum += @as(Number, @truncate(columns));
    }

    io.print("{d}", .{sum});
}

fn findReflection(hashes: []Hash) ?usize {
    for (1..(hashes.len >> 1) + 1) |half_length| {
        if (isReflection(hashes[0 .. half_length * 2]))
            return half_length;
        if (isReflection(hashes[hashes.len - half_length * 2 .. hashes.len]))
            return hashes.len - half_length;
    }
    return null;
}

inline fn isReflection(hashes: []Hash) bool {
    var smudge_found = false;
    for (0..(hashes.len >> 1)) |index| {
        const bit_diff = hashes[index] ^ hashes[hashes.len - 1 - index];
        const pop_count = @popCount(bit_diff);

        if (pop_count > 1 or pop_count == 1 and smudge_found)
            return false;

        if (pop_count == 1)
            smudge_found = true;
    }
    return smudge_found;
}
