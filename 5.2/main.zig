const ArrayList = @import("std").ArrayList;
const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;

const IO = @import("io").IO;

const Number = u64;

const Range = struct {
    start: Number,
    length: Number,
};

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var ranges = ArrayList(Range).init(allocator);
    defer ranges.deinit();

    _ = io.readWord();
    while (!io.eof()) {
        if (io.readInt(Number)) |start| {
            const range_length = io.readInt(Number).?;
            try ranges.append(.{ .start = start, .length = range_length });
        } else {
            _ = io.readLine();
            break;
        }
    }

    while (!io.eof()) {
        var next_ranges = ArrayList(Range).init(allocator);

        while (!io.eof()) {
            const maybe_destination = io.readInt(Number);
            if (maybe_destination == null) {
                _ = io.readLine();
                break;
            }

            const destination = maybe_destination.?;
            const source = io.readInt(Number).?;
            const range_length = io.readInt(Number).?;

            var index: usize = 0;
            while (index < ranges.items.len) {
                var range = &ranges.items[index];
                if (range.start + range.length > source and range.start < source + range_length) {
                    const intersection_start = @max(range.start, source);
                    const intersection_length = @min(range.start + range.length, source + range_length) - intersection_start;
                    try next_ranges.append(.{
                        .start = destination + (intersection_start - source),
                        .length = intersection_length,
                    });

                    if (intersection_start > range.start) {
                        if (intersection_start + intersection_length == range.start + range.length) {
                            range.length -= intersection_length;
                            index += 1;
                        } else {
                            range.length = intersection_start - range.start;
                            // We have a new range
                            try ranges.append(.{
                                .start = intersection_start + intersection_length,
                                .length = range.start + range.length - intersection_start + intersection_length,
                            });
                            index += 1;
                        }
                    } else {
                        if (intersection_length < range.length) {
                            range.start += intersection_length;
                            range.length -= intersection_length;
                            index += 1;
                        } else {
                            // The while range is swallowed
                            _ = ranges.swapRemove(index);
                        }
                    }
                } else index += 1;
            }
        }

        try next_ranges.appendSlice(ranges.items);

        ranges.deinit();
        ranges = next_ranges;
    }

    var min_location = ranges.items[0].start;
    for (ranges.items) |range|
        min_location = @min(min_location, range.start);

    io.print("{d}", .{min_location});
}
