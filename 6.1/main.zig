const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;

const IO = @import("io").IO;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var times: [1024]u16 = undefined;
    var length: usize = 0;

    _ = io.readWord();
    while (true) : (length += 1) {
        if (io.readInt(u16)) |time|
            times[length] = time
        else
            break;
    }

    var result: u64 = 1;

    _ = io.readWord();
    for (0..length) |index| {
        const distance = io.readInt(u16).?;
        result *= computeWays(times[index], distance);
    }

    io.print("{d}", .{result});
}

fn computeWays(time: u16, time_to_beat: u16) u16 {
    if (time_to_beat == 0)
        return time - 1;

    var min: u16 = 0;
    var max = time >> 1;

    if (time_to_beat >= computeTime(time, max))
        return 0;

    while (min < max) {
        const mid = min + max + 1 >> 1;
        if (time_to_beat >= computeTime(time, mid)) {
            min = mid;
        } else {
            max = mid - 1;
        }
    }

    return time - 1 - (min << 1);
}

inline fn computeTime(time: u16, init_time: u16) u16 {
    return (time - init_time) * init_time;
}
