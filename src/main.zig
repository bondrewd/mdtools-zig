const std = @import("std");
const fs = std.fs;
const pdb = @import("pdb.zig");
const ansi = @import("ansi.zig");
const argparse = @import("argparse.zig");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    var args = ArgumentParser.parse(allocator) catch return;
    defer ArgumentParser.deinit(args);

    if (args.help) {
        try ArgumentParser.displayUsage();
        return;
    }

    if (args.version) {
        try ArgumentParser.displayVersion();
        return;
    }
}

const ArgumentParser = argparse.ArgumentParser(.{
    .bin_name = "mdtools",
    .bin_info = "Tools for manipulating Molecular Dynamics (MD) files.",
    .bin_usage = "./mdtools OPTION [OPTION...]",
    .bin_version = .{ .major = 0, .minor = 1, .patch = 0 },
    .display_help = true,
}, &[_]argparse.ParserOption{
    .{
        .name = "input",
        .long = "--input",
        .short = "-i",
        .description = "Input file name",
        .metavar = "<FILE>",
        .argument_type = []const u8,
        .takes = .Many,
    },
    .{
        .name = "output",
        .long = "--output",
        .short = "-o",
        .description = "Output file name (Default: mdtools.out)",
        .metavar = "<FILE>",
        .argument_type = []const u8,
        .takes = .One,
    },
    .{
        .name = "index",
        .long = "--index",
        .short = "-x",
        .description = "Index file name (Default: mdtools.x)",
        .metavar = "<FILE>",
        .argument_type = []const u8,
        .takes = .One,
    },
    .{
        .name = "version",
        .long = "--version",
        .short = "-v",
        .description = "Print mdtools version and exit",
        .argument_type = bool,
    },
    .{
        .name = "help",
        .long = "--help",
        .short = "-h",
        .description = "Display this and exit",
        .argument_type = bool,
    },
});
