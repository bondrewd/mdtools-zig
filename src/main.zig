const std = @import("std");
const clap = @import("./clap.zig");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    var parser = clap.Parser.init(allocator);
    defer parser.deinit();

    parser = parser.addBinName("mdtools").addVersion("0.1.0");
    parser = parser.addDescription("Tools for manipulating MD related files.");

    parser = parser.addArgument(.{
        .name = "input_file",
        .help = "PDB input file (REQUIRED).",
        .meta = "FILE",
    }).addArgument(.{
        .short = "-o",
        .long = "--output",
        .name = "output",
        .help = "Output file name (Default: out.pdb)",
        .takes_value = .One,
        .default_value = &.{"out.pdb"},
    }).addArgument(.{
        .long = "--reset-numeration",
        .name = "reset_numeration",
        .help = "Make numeration in ATOM records start from 1.",
    }).addArgument(.{
        .short = "-v",
        .long = "--version",
        .name = "version",
        .help = "Print version and exit.",
    }).addArgument(.{
        .short = "-h",
        .long = "--help",
        .name = "help",
        .help = "Display this text and exit.",
    });

    try parser.displayUsage();
}
