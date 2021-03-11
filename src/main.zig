const std = @import("std");
const fs = std.fs;
const pdb = @import("./pdb.zig");
const argparse = @import("./argparse.zig");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    var args = try argparse.parse(allocator);

    var pdb_file = try pdb.PdbFile.initFromFile(fs.cwd(), args.input, allocator);

    if (args.cog) |cog| try pdb_file.setCenterOfGeometry(cog);
    if (args.com) |com| try pdb_file.setCenterOfMass(com);
    if (args.align_axes) |axis| {
        switch (axis) {
            .X => try pdb_file.alignPrincipalAxes(.X),
            .Y => try pdb_file.alignPrincipalAxes(.Y),
            .Z => try pdb_file.alignPrincipalAxes(.Z),
        }
    }

    const output = try fs.cwd().createFile(args.output, .{});
    defer output.close();

    try pdb_file.writePdbToFile(output);
}
