const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;

const IO = @import("io").IO;

const Vertex = u16;

const Index = u8;

const Edge = struct {
    to: Vertex,
    len: usize,
};

const StackEdge = struct {
    from: Vertex,
    index: Index,
    len: usize,
};

const max_size = 256;

var edges_buf = [_][5]?Edge{
    [_]?Edge{null} ** 5,
} ** (max_size * max_size);

var width: usize = 0;

var height: usize = 0;

var final: usize = 0;

var stack_buf: [max_size * max_size]StackEdge = undefined;

var stack_len: usize = 0;

var on_stack = [_]bool{false} ** (max_size * max_size);

var max_path_len: usize = 0;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var prev_line: []const u8 = "";

    while (!io.eof()) : (height += 1) {
        const line = io.readLine();

        if (width == 0)
            width = line.len
        else for (line, 0..) |char, x| {
            if (char == '#')
                continue;

            if (x > 0 and line[x - 1] != '#')
                pushEdge(getVertex(x - 1, height), getVertex(x, height));

            if (prev_line[x] != '#')
                pushEdge(getVertex(x, height - 1), getVertex(x, height));
        }

        prev_line = line;
    }

    final = getVertex(width - 2, height - 1);

    for (0..height) |y| {
        for (0..width) |x| {
            const vertex = getVertex(x, y);
            if (edges_buf[vertex][1] != null and edges_buf[vertex][2] == null) {
                const a = edges_buf[vertex][0].?;
                const b = edges_buf[vertex][1].?;

                updateLength(a.to, vertex, b.to, a.len + b.len);
                updateLength(b.to, vertex, a.to, a.len + b.len);

                edges_buf[vertex][0] = null;
                edges_buf[vertex][1] = null;
            }
        }
    }

    pushIfNotOnStack(getVertex(1, 0), 0, 0);

    while (stack_len > 0) {
        const last_edge = &stack_buf[stack_len - 1];
        const edge = edges_buf[last_edge.from][last_edge.index];
        if (edge) |e| {
            last_edge.index += 1;
            pushIfNotOnStack(e.to, 0, last_edge.len + e.len);
        } else pop();
    }

    io.print("{d}", .{max_path_len});
}

fn pushEdge(a: Vertex, b: Vertex) void {
    for (&edges_buf[a]) |*edge|
        if (edge.* == null) {
            edge.* = .{ .to = b, .len = 1 };
            break;
        };

    for (&edges_buf[b]) |*edge|
        if (edge.* == null) {
            edge.* = .{ .to = a, .len = 1 };
            break;
        };
}

fn updateLength(from: Vertex, to: Vertex, new_to: Vertex, len: usize) void {
    for (&edges_buf[from]) |*edge|
        if (edge.*.?.to == to) {
            edge.*.?.to = new_to;
            edge.*.?.len = len;
            break;
        };
}

fn getVertex(x: usize, y: usize) Vertex {
    return @truncate(1 + x + y * width);
}

fn pushIfNotOnStack(from: Vertex, index: Index, len: usize) void {
    if (on_stack[from])
        return;

    if (from == final)
        max_path_len = @max(max_path_len, len);

    stack_buf[stack_len] = .{
        .from = from,
        .index = index,
        .len = len,
    };
    stack_len += 1;
    on_stack[from] = true;
}

fn pop() void {
    stack_len -= 1;
    const edge = stack_buf[stack_len];
    on_stack[edge.from] = false;
}
