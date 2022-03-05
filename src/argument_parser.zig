const argparse = @import("argparse");
const AppOption = argparse.AppOption;

pub const ArgumentParser = argparse.ArgumentParser(.{
    .app_name = "mdtools",
    .app_description = "Tools for manipulating Molecular Dynamics (MD) files.",
    .app_version = .{ .major = 0, .minor = 1, .patch = 0 },
}, &.{
    AppOption{
        .name = "input",
        .short = "-i",
        .long = "--input",
        .metavar = "INPUT",
        .description = "Input file name",
        .required = true,
        .takes = 1,
    },
    AppOption{
        .name = "output",
        .short = "-o",
        .long = "--output",
        .metavar = "OUTPUT",
        .description = "Output file name",
        .takes = 1,
        .default = &.{"out"},
    },
}, &.{});
