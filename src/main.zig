const std = @import("std");
const argparse = @import("./argparse.zig");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    var args = try argparse.parse(allocator);
}
