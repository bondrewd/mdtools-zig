const std = @import("std");
//const Universe = @import("universe.zig").Universe;
const ProgressBar = @import("bar.zig").ProgressBar;

const argparse = @import("argparse-zig/src/argparse.zig");
const ArgumentParser = argparse.ArgumentParser;
const ArgumentParserOption = argparse.ArgumentParserOption;

pub fn main() anyerror!void {
    // Initialize allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    // Get std out writer
    //const stdout = std.io.getStdOut().writer();

    // Get progress bar
    //const progress_bar = ProgressBar.init(stdout, .{});

    // Parse arguments
    const args = try ArgParser.parse(allocator);
    defer ArgParser.deinitArgs(args);

    std.debug.print("args: {?}\n", .{args});

    // Create universe
    //var universe = Universe.init(allocator);
    //defer universe.deinit();

    // Load files
    //for (args.input.items) |file_path| try universe.loadFile(file_path);

    // Write files
    //for (args.output.items) |file_path| try universe.addWriter(file_path);

    // Iterate over the trajectory
    //var i: u32 = 0;
    //while (true) {
    //try progress_bar.write(i, 0, 100);
    //i += 1;
    // Apply periodic boundary conditions
    //if (args.apply_pbc) universe.applyPbc();

    //try universe.write();

    //if (universe.trajectory.n_frames == universe.trajectory.frame) break;
    //try universe.readNextFrame();
    //}
}

const ArgParser = ArgumentParser(.{
    .bin_name = "mdtools",
    .bin_info = "Tools for manipulating Molecular Dynamics (MD) files.",
    .bin_usage = "./mdtools OPTION [OPTION...]",
    .bin_version = .{ .major = 0, .minor = 1, .patch = 0 },
    .display_error = true,
}, [_]ArgumentParserOption{
    .{
        .name = "input",
        .long = "--input",
        .short = "-i",
        .description = "Input file name (Required)",
        .metavar = "<FILE>",
        .argument_type = []const u8,
        .takes = .One,
        .required = true,
    },
    .{
        .name = "output",
        .long = "--output",
        .short = "-o",
        .description = "Output file name (Defult: out.mdtools)",
        .metavar = "<FILE>",
        .argument_type = []const u8,
        .takes = .One,
        .default_value = .{ .string = "out.mdtools" },
    },
});
