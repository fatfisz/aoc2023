const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const StringHashMap = @import("std").StringHashMap;

const IO = @import("io").IO;

const Number = u16;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    const directions = io.readLine();

    _ = io.readLine();

    var node_map = StringHashMap(Number).init(allocator);
    defer node_map.deinit();
    var left: [1024]Number = undefined;
    var right: [1024]Number = undefined;
    while (!io.eof()) {
        const node = io.readWord();
        const node_id = getNodeId(&node_map, node);

        _ = io.readWord();

        const left_node = io.readWord();
        left[node_id] = getNodeId(&node_map, left_node[1 .. left_node.len - 1]);

        const right_node = io.readWord();
        right[node_id] = getNodeId(&node_map, right_node[0 .. right_node.len - 1]);
    }

    const zzz_id = getNodeId(&node_map, "ZZZ");
    var current_id: Number = getNodeId(&node_map, "AAA");
    var directions_index: usize = 0;
    var length: usize = 0;

    while (current_id != zzz_id) : (length += 1) {
        current_id = if (directions[directions_index] == 'L')
            left[current_id]
        else
            right[current_id];

        directions_index = (directions_index + 1) % directions.len;
    }

    io.print("{d}", .{length});
}

fn getNodeId(node_map: *StringHashMap(Number), node: []const u8) Number {
    if (node_map.get(node)) |id|
        return id;

    const next_id = @as(Number, @truncate(node_map.count()));
    node_map.put(node, next_id) catch unreachable;

    return next_id;
}
