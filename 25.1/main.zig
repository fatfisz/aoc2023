const ArrayList = @import("std").ArrayList;
const AutoHashMap = @import("std").AutoHashMap;
const ArenaAllocator = @import("std").heap.ArenaAllocator;
const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const indexOfScalar = @import("std").mem.indexOfScalar;
const StringHashMap = @import("std").StringHashMap;

const IO = @import("io").IO;

const Id = u16;

const max_vertices = 2048;

var queue_buf: [max_vertices]Id = undefined;
var queue_len: usize = 0;

var forbidden_edges_buf = [_]bool{false} ** max_vertices ** max_vertices;

var dist_buf: [max_vertices]Id = undefined;

var found_buf: [3]usize = undefined;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var arena = ArenaAllocator.init(allocator);
    const arena_allocator = arena.allocator();
    defer arena.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var vertex_ids = StringHashMap(Id).init(allocator);
    defer vertex_ids.deinit();
    var edges_buf = [_]?ArrayList(Id){null} ** max_vertices;
    {
        var from = io.readWord();
        while (!io.eof()) {
            const from_id = getIdOrCreate(&vertex_ids, from[0 .. from.len - 1]);
            if (edges_buf[from_id] == null)
                edges_buf[from_id] = ArrayList(Id).init(arena_allocator);

            while (!io.eof()) {
                const to = io.readWord();
                if (to[to.len - 1] == ':') {
                    from = to;
                    break;
                }
                const to_id = getIdOrCreate(&vertex_ids, to);
                if (edges_buf[to_id] == null)
                    edges_buf[to_id] = ArrayList(Id).init(arena_allocator);

                try edges_buf[from_id].?.append(to_id);
                try edges_buf[to_id].?.append(from_id);
            }
        }
    }
    const max_id = vertex_ids.count();
    const edges = blk: {
        var edges = [_][]Id{&[_]Id{}} ** max_vertices;
        for (0..max_id) |id|
            edges[id] = edges_buf[id].?.items;
        break :blk edges[0..max_id];
    };

    var forbidden_edges = AutoHashMap(usize, void).init(allocator);
    defer forbidden_edges.deinit();

    const result = result: {
        find_next: for (0..3) |found_len| {
            for (0..edges.len) |a| {
                for (edges[a]) |b| {
                    if (indexOfScalar(usize, found_buf[0..found_len], getEdgeId(a, b)) != null)
                        continue;

                    forbidden_edges.clearRetainingCapacity();
                    for (0..found_len) |index|
                        try forbidden_edges.put(found_buf[index], {});
                    try forbidden_edges.put(getEdgeId(a, b), {});

                    const max_iterations = 3 - found_len;

                    bfs: for (0..max_iterations) |iteration| {
                        @memset(dist_buf[0..max_id], 0);
                        queue_buf[0] = @truncate(a);
                        queue_len = 1;
                        var index: usize = 0;

                        while (index < queue_len) : (index += 1) {
                            const from = queue_buf[index];
                            if (from == b) {
                                if (iteration == max_iterations - 1)
                                    break :bfs;

                                break;
                            }

                            for (edges[from]) |to|
                                if (!forbidden_edges.contains(getEdgeId(from, to)) and to != a and dist_buf[to] == 0) {
                                    dist_buf[to] = dist_buf[from] + 1;
                                    queue_buf[queue_len] = to;
                                    queue_len += 1;
                                };
                        }

                        if (iteration == max_iterations - 1) {
                            if (found_len == 2)
                                break :result queue_len * (max_id - queue_len);

                            found_buf[found_len] = getEdgeId(a, b);
                            continue :find_next;
                        }

                        var to = b;
                        while (to != a) {
                            for (edges[to]) |from| {
                                if (!forbidden_edges.contains(getEdgeId(from, to)) and
                                    (from == a or dist_buf[from] > 0) and
                                    dist_buf[from] < dist_buf[to])
                                {
                                    try forbidden_edges.put(getEdgeId(from, to), {});
                                    to = from;
                                    break;
                                }
                            } else unreachable;
                        }
                    }
                }
            }
        }
        unreachable;
    };

    io.print("{d}", .{result});
}

fn getIdOrCreate(id_map: *StringHashMap(Id), value: []const u8) Id {
    if (id_map.get(value)) |id|
        return id;
    const next_id: Id = @truncate(id_map.count());
    id_map.put(value, next_id) catch unreachable;
    return next_id;
}

fn getEdgeId(a: usize, b: usize) usize {
    return @min(a, b) * max_vertices + @max(a, b);
}
