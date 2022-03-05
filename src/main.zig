const std = @import("std");
//const Universe = @import("universe.zig").Universe;
const ProgressBar = @import("progress_bar.zig").ProgressBar;

const ArgumentParser = @import("argument_parser.zig").ArgumentParser;

pub fn main() anyerror!void {
    // Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    // Get Arguments
    var args = ArgumentParser.parseArgumentsAllocator(allocator) catch return;
    std.debug.print("input: {s}\n", .{args.input});
    std.debug.print("output: {s}\n", .{args.output});

    // Get stdout
    const stdout = std.io.getStdOut().writer();

    // Get progress bar
    const progress_bar = ProgressBar.init(.{});

    // Create universe
    //var universe = Universe.init(allocator);
    //defer universe.deinit();

    // Load files
    //for (args.input.items) |file_path| try universe.loadFile(file_path);

    // Write files
    //for (args.output.items) |file_path| try universe.addWriter(file_path);

    // Iterate over the trajectory
    var i: u32 = 0;
    while (i <= 100) : (i += 1) {
        try progress_bar.displayProgressWriter(i, 0, 100, stdout);
        // Apply periodic boundary conditions
        //if (args.apply_pbc) universe.applyPbc();

        //try universe.write();

        //if (universe.trajectory.n_frames == universe.trajectory.frame) break;
        //try universe.readNextFrame();
    }
}
