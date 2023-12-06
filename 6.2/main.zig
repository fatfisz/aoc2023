const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;

const IO = @import("io").IO;

const Number = u64;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    _ = io.readWord();
    const time_line = io.readLine();
    var time_buf: [1024]u8 = undefined;
    var time_length: usize = 0;

    for (time_line) |char|
        if (IO.isDigit(char)) {
            time_buf[time_length] = char;
            time_length += 1;
        };
    const time = IO.asInt(Number, time_buf[0..time_length]).?;

    _ = io.readWord();
    const distance_line = io.readLine();
    var distance_buf: [1024]u8 = undefined;
    var distance_length: usize = 0;

    for (distance_line) |char|
        if (IO.isDigit(char)) {
            distance_buf[distance_length] = char;
            distance_length += 1;
        };
    const distance = IO.asInt(Number, distance_buf[0..distance_length]).?;

    const result = computeWays(time, distance);

    io.print("{d}", .{result});
}

fn computeWays(time: Number, time_to_beat: Number) Number {
    if (time_to_beat == 0)
        return time - 1;

    var min: Number = 0;
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

inline fn computeTime(time: Number, init_time: Number) Number {
    return (time - init_time) * init_time;
}
