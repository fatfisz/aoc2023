const ArrayList = @import("std").ArrayList;
const EnumArray = @import("std").EnumArray;
const ArenaAllocator = @import("std").heap.ArenaAllocator;
const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const maxInt = @import("std").math.maxInt;
const eql = @import("std").mem.eql;
const indexOfScalar = @import("std").mem.indexOfScalar;
const StringHashMap = @import("std").StringHashMap;

const IO = @import("io").IO;

const Sum = u64;

const Number = u16;

const Rule = union(enum) {
    accept,
    reject,
    goto: Number,
    condition: struct {
        rating_name: RatingName,
        gt: bool,
        value: Number,
        result: ConditionResult,
    },
};

const RatingName = enum { x, m, a, s };

const ConditionResult = union(enum) {
    accept,
    reject,
    goto: Number,
};

const Workflow = struct {
    id: Number,
    index: usize,
    rating_ranges: RatingRanges,
};

const RatingRanges = EnumArray(RatingName, Range);

const Range = struct {
    lo: Number = 1,
    hi: Number = 4000,
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

    var workflow_stack = ArrayList(Workflow).init(allocator);
    defer workflow_stack.deinit();

    try workflow_stack.append(.{
        .id = getIdOrCreate(&workflow_ids, "in"),
        .index = 0,
        .rating_ranges = EnumArray(RatingName, Range).initFill(.{}),
    });

    var sum: Sum = 4000 * 4000 * 4000 * 4000;
    while (workflow_stack.items.len > 0) {
        var workflow = &workflow_stack.items[workflow_stack.items.len - 1];
        if (workflow.index == workflow_rules[workflow.id].len) {
            _ = workflow_stack.pop();
            continue;
        }

        const rule = workflow_rules[workflow.id][workflow.index];
        workflow.index += 1;

        switch (rule) {
            .accept => _ = workflow_stack.pop(),
            .reject => {
                sum -= getRatingRangesSize(workflow.rating_ranges);
                _ = workflow_stack.pop();
            },
            .goto => |id| try workflow_stack.append(.{
                .id = id,
                .index = 0,
                .rating_ranges = workflow.rating_ranges,
            }),
            .condition => |condition| {
                var current_rating_ranges = workflow.rating_ranges;
                const current_rating = current_rating_ranges.getPtr(condition.rating_name);
                const rating = (&workflow.rating_ranges).getPtr(condition.rating_name);
                if (condition.gt) {
                    current_rating.lo = condition.value + 1;
                    rating.hi = condition.value;
                } else {
                    current_rating.hi = condition.value - 1;
                    rating.lo = condition.value;
                }
                switch (condition.result) {
                    .accept => {},
                    .reject => sum -= getRatingRangesSize(current_rating_ranges),
                    .goto => |id| try workflow_stack.append(.{
                        .id = id,
                        .index = 0,
                        .rating_ranges = current_rating_ranges,
                    }),
                }
            },
        }
    }

    io.print("{d}", .{sum});
}

fn getRatingRangesSize(rating_ranges: RatingRanges) Sum {
    return @as(Sum, rating_ranges.get(.x).hi - rating_ranges.get(.x).lo + 1) *
        @as(Sum, rating_ranges.get(.m).hi - rating_ranges.get(.m).lo + 1) *
        @as(Sum, rating_ranges.get(.a).hi - rating_ranges.get(.a).lo + 1) *
        @as(Sum, rating_ranges.get(.s).hi - rating_ranges.get(.s).lo + 1);
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
        const rating_name = parseRatingName(input[0]);
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

fn parseRatingName(input: u8) RatingName {
    return switch (input) {
        'x' => .x,
        'm' => .m,
        'a' => .a,
        's' => .s,
        else => unreachable,
    };
}
