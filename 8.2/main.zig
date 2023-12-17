const ArrayList = @import("std").ArrayList;
const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const StringHashMap = @import("std").StringHashMap;

const IO = @import("io").IO;

const Number = u64;

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
    var start_ids_list = ArrayList(Number).init(allocator);
    defer start_ids_list.deinit();
    var left: [1024]Number = undefined;
    var right: [1024]Number = undefined;
    var is_end_id = [_]bool{false} ** 1024;
    while (!io.eof()) {
        const node = io.readWord();
        const node_id = getNodeId(&node_map, node);

        switch (node[node.len - 1]) {
            'A' => try start_ids_list.append(node_id),
            'Z' => is_end_id[node_id] = true,
            else => {},
        }

        _ = io.readWord();

        const left_node = io.readWord();
        left[node_id] = getNodeId(&node_map, left_node[1 .. left_node.len - 1]);

        const right_node = io.readWord();
        right[node_id] = getNodeId(&node_map, right_node[0 .. right_node.len - 1]);
    }

    var lcm: Number = 1;

    const start_ids = try start_ids_list.toOwnedSlice();
    defer allocator.free(start_ids);
    for (start_ids) |start_id| {
        var current_id = start_id;
        var directions_index: usize = 0;
        var length: Number = 0;

        while (!is_end_id[current_id]) : (length += 1) {
            current_id = if (directions[directions_index] == 'L')
                left[current_id]
            else
                right[current_id];

            directions_index = (directions_index + 1) % directions.len;
        }

        lcm = getLcm(lcm, length);
    }

    io.print("{d}", .{lcm});
}

fn getNodeId(node_map: *StringHashMap(Number), node: []const u8) Number {
    if (node_map.get(node)) |id|
        return id;

    const next_id: Number = node_map.count();
    node_map.put(node, next_id) catch unreachable;

    return next_id;
}

fn getLcm(number1: Number, number2: Number) Number {
    var n1 = number1;
    var n2 = number2;

    while (n1 != 0) {
        const next_n1 = n2 % n1;
        n2 = n1;
        n1 = next_n1;
    }

    return number1 / n2 * number2;
}
