const std = @import("std");
const ansi = @import("ansi.zig");
const parser = @import("parser.zig");

const reset = ansi.reset;
const bold = ansi.txt_bold;
const green = ansi.txt_fg_green;

pub fn main() anyerror!void {
    // Initialize allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    // Get std out writer
    const stdout = std.io.getStdOut().writer();

    var args = ArgumentParser.parse(allocator) catch |err| switch (err) {
        error.OptionAppearsTwoTimes, error.MissingArgument, error.UnknownArgument => {
            try stdout.writeAll("Try " ++ bold ++ green ++ "-h" ++ reset ++ " for more information.\n");
            return;
        },
        error.NoArgument => {
            try ArgumentParser.displayUsage();
            return;
        },
        else => {
            try stdout.writeAll("An unknown error ocurred.\n");
            return;
        },
    };
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

const ArgumentParser = parser.ArgumentParser(.{
    .bin_name = "mdtools",
    .bin_info = "Tools for manipulating Molecular Dynamics (MD) files.",
    .bin_usage = "./mdtools OPTION [OPTION...]",
    .bin_version = .{ .major = 0, .minor = 1, .patch = 0 },
    .display_help = true,
}, &[_]parser.ArgumentParserOption{
    .{
        .name = "input",
        .long = "--input",
        .short = "-i",
        .description = "Input file name",
        .metavar = "<FILE> [FILE...]",
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
        .metavar = "<FILE> [FILE...]",
        .argument_type = []const u8,
        .takes = .Many,
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
