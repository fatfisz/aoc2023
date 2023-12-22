const ArrayList = @import("std").ArrayList;
const ArenaAllocator = @import("std").heap.ArenaAllocator;
const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const indexOfScalar = @import("std").mem.indexOfScalar;
const StringHashMap = @import("std").StringHashMap;

const IO = @import("io").IO;

const ModuleType = enum { broadcaster, empty, flip_flop, conjunction };

const ModuleState = union(ModuleType) {
    broadcaster,
    empty,
    flip_flop: bool,
    conjunction: struct {
        inputs: ArrayList(Id),
        value: Conjunction,
    },
};

const Signal = struct {
    source_id: Id,
    id: Id,
    value: bool,
};

const Number = u32;

const Id = u8;

const Conjunction = u16;

const max_modules = 256;

const max_all_edges = 1024;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var arena = ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var io = try IO.init(allocator);
    defer io.deinit();

    var module_ids = StringHashMap(Id).init(allocator);
    defer module_ids.deinit();

    var module_states_buf = [_]ModuleState{.{ .empty = {} }} ** max_modules;
    var destinations_buf: [max_all_edges]Id = undefined;
    var destinations_len: usize = 0;
    var destination_lists_buf = [_][]Id{destinations_buf[0..0]} ** max_modules;
    while (!io.eof()) {
        var name = io.readWord();
        const module_type: ModuleType = switch (name[0]) {
            '%' => blk: {
                name = name[1..];
                break :blk .flip_flop;
            },
            '&' => blk: {
                name = name[1..];
                break :blk .conjunction;
            },
            else => .broadcaster,
        };
        const id = getIdOrCreate(&module_ids, name);

        _ = io.readWord();

        const start_index = destinations_len;
        while (true) {
            var destination_name = io.readWord();
            const is_last = destination_name[destination_name.len - 1] != ',';

            if (!is_last)
                destination_name = destination_name[0 .. destination_name.len - 1];

            const destination_id = getIdOrCreate(&module_ids, destination_name);
            destinations_buf[destinations_len] = destination_id;
            destinations_len += 1;

            if (is_last)
                break;
        }
        destination_lists_buf[id] = destinations_buf[start_index..destinations_len];

        module_states_buf[id] = switch (module_type) {
            .broadcaster => .{ .broadcaster = {} },
            .flip_flop => .{ .flip_flop = false },
            .conjunction => .{ .conjunction = .{
                .inputs = ArrayList(Id).init(arena_allocator),
                .value = 0,
            } },
            else => unreachable,
        };
    }
    const module_states = module_states_buf[0..module_ids.count()];
    const destination_lists = destination_lists_buf[0..module_ids.count()];

    for (0..module_ids.count()) |source_id|
        for (destination_lists[source_id]) |id|
            if (module_states[id] == .conjunction) {
                try module_states[id].conjunction.inputs.append(@truncate(source_id));
                if (module_states[id].conjunction.inputs.items.len > @bitSizeOf(Conjunction))
                    @import("std").debug.panic(
                        "Overflow: the Conjunction type has {d} bits, needs more",
                        .{@bitSizeOf(Conjunction)},
                    );
            };

    var signals = ArrayList(Signal).init(allocator);
    defer signals.deinit();

    const button_id = getIdOrCreate(&module_ids, "button");
    const broadcaster_id = getIdOrCreate(&module_ids, "broadcaster");
    var low_count: Number = 0;
    var high_count: Number = 0;
    for (0..1000) |_| {
        signals.clearRetainingCapacity();
        try signals.append(.{ .source_id = button_id, .id = broadcaster_id, .value = false });
        var index: usize = 0;
        while (index < signals.items.len) : (index += 1) {
            const signal = signals.items[index];
            switch (module_states[signal.id]) {
                .broadcaster => {
                    for (destination_lists[signal.id]) |id|
                        try signals.append(.{ .source_id = signal.id, .id = id, .value = signal.value });
                },
                .empty => {},
                .flip_flop => |*state| {
                    if (!signal.value) {
                        state.* = !state.*;
                        for (destination_lists[signal.id]) |id|
                            try signals.append(.{ .source_id = signal.id, .id = id, .value = state.* });
                    }
                },
                .conjunction => |*state| {
                    const input_index = indexOfScalar(Id, state.inputs.items, signal.source_id).?;
                    if (signal.value)
                        state.value |= @as(Id, 1) << @truncate(input_index)
                    else
                        state.value &= ~(@as(Id, 1) << @truncate(input_index));
                    const output = @popCount(state.value) != state.inputs.items.len;
                    for (destination_lists[signal.id]) |id|
                        try signals.append(.{ .source_id = signal.id, .id = id, .value = output });
                },
            }
        }
        for (signals.items) |signal| {
            if (signal.value)
                high_count += 1
            else
                low_count += 1;
        }
    }

    io.print("{d}", .{low_count * high_count});
}

fn getIdOrCreate(id_map: *StringHashMap(Id), value: []const u8) Id {
    if (id_map.get(value)) |id|
        return id;
    const next_id: Id = @truncate(id_map.count());
    id_map.put(value, next_id) catch unreachable;
    return next_id;
}
