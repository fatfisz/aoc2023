const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const tokenizeScalar = @import("std").mem.tokenizeScalar;

const IO = @import("io").IO;

const Number = u64;

const expansion = 1000000;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var image: [1024][]const u8 = undefined;
    var height: usize = 0;

    while (!io.eof()) : (height += 1)
        image[height] = io.readLine();

    const width = image[0].len;

    var sum: Number = 0;
    var galaxies_so_far: Number = 0;
    var lengths: Number = 0;
    for (0..height) |y| {
        var galaxy_found = false;
        for (0..width) |x| {
            if (image[y][x] == '#') {
                galaxy_found = true;
                sum += lengths;
                galaxies_so_far += 1;
            }
        }
        const mod: Number = if (galaxy_found) 1 else expansion;
        lengths += galaxies_so_far * mod;
    }

    galaxies_so_far = 0;
    lengths = 0;
    for (0..width) |x| {
        var galaxy_found = false;
        for (0..height) |y| {
            if (image[y][x] == '#') {
                galaxy_found = true;
                sum += lengths;
                galaxies_so_far += 1;
            }
        }
        const mod: Number = if (galaxy_found) 1 else expansion;
        lengths += galaxies_so_far * mod;
    }

    io.print("{d}", .{sum});
}
