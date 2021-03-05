const std = @import("std");
const fs = std.fs;
const io = std.io;
const os = std.os;
const fmt = std.fmt;
const pdb = @import("./pdb.zig");
const argparse = @import("./argparse.zig");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    var args = try argparse.parse(allocator);

    var pdb_file = try pdb.PdbFile.initFromFile(fs.cwd(), args.input, allocator);

    const output = try fs.cwd().createFile(args.output, .{});
    defer output.close();

    try pdb_file.writePdbToFile(output);
}
