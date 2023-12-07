const GeneralPurposeAllocator = @import("std").heap.GeneralPurposeAllocator;
const indexOfMax = @import("std").mem.indexOfMax;
const sort = @import("std").mem.sort;

const IO = @import("io").IO;

const Number = u64;

const cards = "AKQT98765432J";

const strength = blk: {
    var map: [128]u8 = undefined;

    for (cards, 0..) |card, index|
        map[card] = index;

    break :blk map;
};

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var io = try IO.init(allocator);
    defer io.deinit();

    var hands: [1024][]const u8 = undefined;
    var bids: [1024]u16 = undefined;
    var indices: [1024]u16 = undefined;
    var length: usize = 0;
    while (!io.eof()) : (length += 1) {
        hands[length] = io.readWord();
        bids[length] = io.readInt(u16).?;
        indices[length] = @as(u16, @truncate(length));
    }

    sort(
        u16,
        indices[0..length],
        SortContext{ .hands = hands[0..length], .bids = bids[0..length] },
        SortContext.lessThan,
    );

    var sum: u32 = 0;
    for (indices[0..length], 0..) |index, number|
        sum += bids[index] * @as(u32, @truncate(length - number));

    io.print("{d}", .{sum});
}

const SortContext = struct {
    hands: [][]const u8,
    bids: []u16,

    fn lessThan(self: SortContext, lhs: u16, rhs: u16) bool {
        const lhs_hand = self.hands[lhs];
        const rhs_hand = self.hands[rhs];
        const lhs_type = getType(lhs_hand);
        const rhs_type = getType(rhs_hand);

        if (lhs_type < rhs_type) return true;
        if (lhs_type > rhs_type) return false;

        for (lhs_hand, 0..) |card, index| {
            const lhs_strength = strength[card];
            const rhs_strength = strength[rhs_hand[index]];
            if (lhs_strength < rhs_strength) return true;
            if (lhs_strength > rhs_strength) return false;
        }

        return false;
    }
};

// Five of a kind, where all five cards have the same label: AAAAA
// Four of a kind, where four cards have the same label and one card has a different label: AA8AA
// Full house, where three cards have the same label, and the remaining two cards share a different label: 23332
// Three of a kind, where three cards have the same label, and the remaining two cards are each different from any other card in the hand: TTT98
// Two pair, where two cards share one label, two other cards share a second label, and the remaining card has a third label: 23432
// One pair, where two cards share one label, and the other three cards have a different label from the pair and each other: A23A4
// High card, where all cards' labels are distinct: 23456

fn getType(hand: []const u8) u8 {
    var count = [_]u8{0} ** cards.len;

    for (hand) |card|
        count[strength[card]] += 1;

    const joker_count = count[strength['J']];
    count[strength['J']] = 0;
    count[indexOfMax(u8, &count)] += joker_count;

    if (countValue(u8, &count, 5) == 1)
        return 0;

    if (countValue(u8, &count, 4) == 1)
        return 1;

    if (countValue(u8, &count, 3) == 1)
        return 3 - @as(u8, @truncate(countValue(u8, &count, 2)));

    return 6 - @as(u8, @truncate(countValue(u8, &count, 2)));
}

inline fn countValue(comptime T: type, slice: []const T, value: T) usize {
    var result: usize = 0;

    for (slice) |item| {
        if (item == value)
            result += 1;
    }

    return result;
}
