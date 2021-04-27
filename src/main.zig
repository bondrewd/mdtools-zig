const std = @import("std");
const ansi = @import("ansi.zig");
const parser = @import("parser.zig");
const Universe = @import("universe.zig").Universe;
const ProgressBar = @import("bar.zig").ProgressBar;

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

    // Get progress bar
    const progress_bar = ProgressBar.init(stdout, .{});

    // Parse arguments
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

    // Print help menu if requested, and exit
    if (args.help) {
        try ArgumentParser.displayUsage();
        return;
    }

    // Print version if requested, and exit
    if (args.version) {
        try ArgumentParser.displayVersion();
        return;
    }

    // Create universe
    var universe = Universe.init(allocator);
    defer universe.deinit();

    // Load files
    for (args.input.items) |file_path| try universe.loadFile(file_path);

    // Write files
    for (args.output.items) |file_path| try universe.addWriter(file_path);

    // Iterate over the trajectory
    var i: u32 = 0;
    while (true) {
        try progress_bar.write(i, 0, 100);
        i += 1;
        // Apply periodic boundary conditions
        if (args.apply_pbc) universe.applyPbc();

        try universe.write();

        if (universe.trajectory.n_frames == universe.trajectory.frame) break;
        try universe.readNextFrame();
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
        .description = "Output file name",
        .metavar = "<FILE> [FILE...]",
        .argument_type = []const u8,
        .takes = .Many,
    },
    .{
        .name = "apply_pbc",
        .long = "--apply-pbc",
        .description = "Apply PBC to all the particles in the system",
        .argument_type = bool,
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
