const ArrayList = @import("std").ArrayList;
const ArenaAllocator = @import("std").heap.ArenaAllocator;
const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const maxInt = @import("std").math.maxInt;
const eql = @import("std").mem.eql;
const indexOfScalar = @import("std").mem.indexOfScalar;
const StringHashMap = @import("std").StringHashMap;

const IO = @import("io").IO;

const Sum = u32;

const Number = u16;

const Rule = union(enum) {
    accept,
    reject,
    goto: Number,
    condition: struct {
        rating_name: u8,
        gt: bool,
        value: Number,
        result: ConditionResult,
    },
};

const ConditionResult = union(enum) {
    accept,
    reject,
    goto: Number,
};

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var arena = ArenaAllocator.init(allocator);
    const arena_allocator = arena.allocator();
    defer arena.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var workflow_ids = StringHashMap(Number).init(allocator);
    defer workflow_ids.deinit();

    var workflow_rules_buf: [1024][]Rule = undefined;
    while (io.readWhile('\n').len != 2) {
        const name = io.readUntil('{');
        _ = io.readChar();
        const id = getIdOrCreate(&workflow_ids, name);
        var rules = ArrayList(Rule).init(arena_allocator);

        while (true) {
            try rules.append(parseRule(&workflow_ids, io.readUntilAny(",}")));

            if (io.readChar() == '}')
                break;
        }

        workflow_rules_buf[id] = try rules.toOwnedSlice();
    }
    const workflow_rules = workflow_rules_buf[0..workflow_ids.count()];

    const start_id = getIdOrCreate(&workflow_ids, "in");
    var sum: Sum = 0;
    while (!io.eof()) {
        var ratings: [maxInt(u8)]Number = undefined;
        _ = io.readChar();

        while (true) {
            const rating_name = io.readChar();
            _ = io.readChar();
            ratings[rating_name] = io.readInt(Number).?;

            if (io.readChar() == '}')
                break;
        }

        var accepted = false;
        var current_id = start_id;
        outer: while (true) {
            for (workflow_rules[current_id]) |rule| {
                switch (rule) {
                    .accept => {
                        accepted = true;
                        break :outer;
                    },
                    .reject => break :outer,
                    .goto => |id| {
                        current_id = id;
                        continue :outer;
                    },
                    .condition => |condition| {
                        var rating_value = ratings[condition.rating_name];
                        const fulfilled = if (condition.gt)
                            rating_value > condition.value
                        else
                            rating_value < condition.value;
                        if (fulfilled) switch (condition.result) {
                            .accept => {
                                accepted = true;
                                break :outer;
                            },
                            .reject => break :outer,
                            .goto => |id| {
                                current_id = id;
                                continue :outer;
                            },
                        };
                    },
                }
            }
        }

        if (accepted)
            sum += ratings['x'] + ratings['m'] + ratings['a'] + ratings['s'];

        if (!io.eof())
            _ = io.readLine();
    }

    io.print("{d}", .{sum});
}

fn getIdOrCreate(id_map: *StringHashMap(Number), value: []const u8) Number {
    if (id_map.get(value)) |id|
        return id;
    const next_id: Number = @truncate(id_map.count());
    id_map.put(value, next_id) catch unreachable;
    return next_id;
}

fn parseRule(id_map: *StringHashMap(Number), input: []const u8) Rule {
    if (eql(u8, input, "A"))
        return .{ .accept = {} };

    if (eql(u8, input, "R"))
        return .{ .reject = {} };

    if (indexOfScalar(u8, input, ':')) |i| {
        const rating_name = input[0];
        const gt = input[1] == '>';
        const value = IO.asInt(Number, input[2..i]).?;
        const result: ConditionResult = if (eql(u8, input[i + 1 ..], "A"))
            .{ .accept = {} }
        else if (eql(u8, input[i + 1 ..], "R"))
            .{ .reject = {} }
        else
            .{ .goto = getIdOrCreate(id_map, input[i + 1 ..]) };

        return .{ .condition = .{
            .rating_name = rating_name,
            .gt = gt,
            .value = value,
            .result = result,
        } };
    } else {
        return .{ .goto = getIdOrCreate(id_map, input) };
    }
}
