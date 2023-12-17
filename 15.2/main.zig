const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const eql = @import("std").mem.eql;

const IO = @import("io").IO;

const Number = u32;

const Lens = struct {
    label: []const u8,
    focal_length: u8,
};

const max_box_size = 32;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var boxes_buf = [_][max_box_size]?Lens{
        [_]?Lens{null} ** max_box_size,
    } ** 256;
    var box_sizes = [_]u8{0} ** 256;

    while (!io.eof()) {
        const label = io.readUntilAny("=-");
        var box_index = getHash(label);
        var remove = io.readChar() == '-';
        var focal_length = if (remove) 0 else io.readChar() - '0';

        if (!io.eof()) _ = io.readChar();

        const box_size = box_sizes[box_index];
        if (remove) {
            for (boxes_buf[box_index][0..box_size]) |*lens|
                if (lens.* != null and eql(u8, lens.*.?.label, label)) {
                    lens.* = null;
                    break;
                };
        } else {
            for (boxes_buf[box_index][0..box_size]) |*lens| {
                if (lens.* != null and eql(u8, lens.*.?.label, label)) {
                    lens.*.?.focal_length = focal_length;
                    break;
                }
            } else {
                boxes_buf[box_index][box_size] = .{
                    .label = label,
                    .focal_length = focal_length,
                };
                box_sizes[box_index] += 1;
            }
        }
    }

    var sum: Number = 0;

    for (0..256) |box_index| {
        var holes: Number = 0;
        for (boxes_buf[box_index][0..box_sizes[box_index]], 0..) |lens, index| {
            if (lens) |l|
                sum +=
                    (@as(Number, @truncate(box_index)) + 1) *
                    (@as(Number, @truncate(index)) + 1 - holes) *
                    l.focal_length
            else
                holes += 1;
        }
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
