const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const tokenizeScalar = @import("std").mem.tokenizeScalar;

const IO = @import("io").IO;

const Number = i32;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var numbers: [1024]Number = undefined;
    var diff: [1024]Number = undefined;
    var count: usize = undefined;

    var sum: Number = 0;

    while (!io.eof()) {
        count = 0;
        const line = io.readLine();
        var it = tokenizeScalar(u8, line, ' ');
        while (it.next()) |word| : (count += 1)
            numbers[count] = IO.asInt(Number, word).?;

        sum += numbers[0];
        @memcpy(diff[0..count], numbers[0..count]);
        var iteration: usize = 1;

        while (true) : (iteration += 1) {
            var index: usize = 0;
            var all_zero = true;
            while (index < count - iteration) : (index += 1) {
                diff[index] = diff[index + 1] - diff[index];
                if (diff[index] != 0)
                    all_zero = false;
            }

            if (all_zero)
                break;

            if (iteration % 2 == 1)
                sum -= diff[0]
            else
                sum += diff[0];
        }
    }

    io.print("{d}", .{sum});
}
