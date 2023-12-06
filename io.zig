const parseInt = @import("std").fmt.parseInt;
const cwd = @import("std").fs.cwd;
const File = @import("std").fs.File;
const Allocator = @import("std").mem.Allocator;
const endsWith = @import("std").mem.endsWith;
const indexOfAnyPos = @import("std").mem.indexOfAnyPos;
const indexOfNonePos = @import("std").mem.indexOfNonePos;
const indexOfScalarPos = @import("std").mem.indexOfScalarPos;
const trim = @import("std").mem.trim;
const argsWithAllocator = @import("std").process.argsWithAllocator;

pub const IO = struct {
    // 100 MB
    const max_file_size = 1e9;

    allocator: Allocator,
    input: []const u8,
    trimmed_input: []const u8,
    input_index: usize,
    output_file: File,
    output_writer: File.Writer,

    pub fn init(allocator: Allocator) !IO {
        const parameters = try Parameters.init(allocator);
        defer parameters.deinit();

        const input = try cwd().readFileAlloc(allocator, parameters.input, max_file_size);
        const output_file = try cwd().createFile(parameters.output, .{});
        const output_writer = output_file.writer();

        return .{
            .allocator = allocator,
            .input = input,
            .trimmed_input = trim(u8, input, "\n "),
            .input_index = 0,
            .output_file = output_file,
            .output_writer = output_writer,
        };
    }

    pub fn eof(self: IO) bool {
        return self.input_index == self.trimmed_input.len;
    }

    fn readUntil(self: *IO, value: u8) []const u8 {
        // Check this before calling the method
        if (self.eof()) unreachable;

        const pos =
            indexOfScalarPos(u8, self.trimmed_input, self.input_index, value) orelse
            self.trimmed_input.len;

        defer self.input_index = pos;
        return self.trimmed_input[self.input_index..pos];
    }

    fn readUntilAny(self: *IO, values: []const u8) []const u8 {
        // Check this before calling the method
        if (self.eof()) unreachable;

        const pos =
            indexOfAnyPos(u8, self.trimmed_input, self.input_index, values) orelse
            self.trimmed_input.len;

        defer self.input_index = pos;
        return self.trimmed_input[self.input_index..pos];
    }

    fn readWhile(self: *IO, value: u8) void {
        if (self.eof()) return;

        while (!self.eof() and self.trimmed_input[self.input_index] == value)
            self.input_index += 1;
    }

    fn readWhileAny(self: *IO, values: []const u8) void {
        if (self.eof()) return;

        self.input_index =
            indexOfNonePos(u8, self.trimmed_input, self.input_index, values) orelse
            self.trimmed_input.len;
    }

    pub fn readLine(self: *IO) []const u8 {
        const line = self.readUntil('\n');

        if (!self.eof())
            self.input_index += 1;

        return line;
    }

    pub fn readWord(self: *IO) []const u8 {
        const line = self.readUntilAny("\n ");
        self.readWhileAny("\n ");

        return line;
    }

    pub fn asInt(comptime T: type, word: []const u8) ?T {
        return parseInt(T, word, 10) catch null;
    }

    pub fn isDigit(value: u8) bool {
        return value >= '0' and value <= '9';
    }

    pub fn readInt(self: *IO, comptime T: type) ?T {
        const start = self.input_index;

        while (!self.eof() and isDigit(self.trimmed_input[self.input_index]))
            self.input_index += 1;

        defer self.readWhileAny("\n ");

        return asInt(T, self.trimmed_input[start..self.input_index]);
    }

    pub fn print(self: IO, comptime format: []const u8, args: anytype) void {
        self.output_writer.print(format, args) catch unreachable;
    }

    pub fn deinit(self: IO) void {
        self.allocator.free(self.input);
        self.output_file.close();
    }
};

const Parameters = struct {
    const input_suffix = ".in";
    const output_suffix = ".out";

    allocator: Allocator,
    input: []const u8,
    output: []const u8,

    fn init(allocator: Allocator) !Parameters {
        var args = try argsWithAllocator(allocator);
        defer args.deinit();

        _ = args.skip();

        const name: []const u8 = if (args.next()) |a|
            if (endsWith(u8, a, input_suffix)) a[0 .. a.len - input_suffix.len] else a
        else
            @import("std").debug.panic("Expected an input file name", .{});

        const input = try allocator.alloc(u8, name.len + input_suffix.len);
        errdefer allocator.free(input);

        @memcpy(input.ptr, name);
        @memcpy(input.ptr + name.len, input_suffix);

        const output = try allocator.alloc(u8, name.len + output_suffix.len);
        errdefer allocator.free(output);

        @memcpy(output.ptr, name);
        @memcpy(output.ptr + name.len, output_suffix);

        return .{
            .allocator = allocator,
            .input = input,
            .output = output,
        };
    }

    fn deinit(self: Parameters) void {
        self.allocator.free(self.input);
        self.allocator.free(self.output);
    }
};
