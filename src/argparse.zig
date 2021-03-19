const std = @import("std");
const io = std.io;
const fmt = std.fmt;
const eql = std.mem.eql;
const len = std.mem.len;
const exit = std.os.exit;

const version = "0.1.0";

pub fn displayUsage() !void {
    const out = io.getStdOut();
    _ = try out.write("mdtools " ++ version ++ "\n\n");
    _ = try out.write("Tools for manipulating MD related files.\n\n");

    _ = try out.write("USAGE\n");
    _ = try out.write("./mdtools [OPTION]\n\n");

    _ = try out.write("OPTIONS\n");
    _ = try out.write("    -i, --input <FILE>\n");
    _ = try out.write("\tInput file name\n\n");

    _ = try out.write("    -o, --output <NAME>\n");
    _ = try out.write("\tOutput file name (Default: out)\n\n");

    _ = try out.write("        --set-cog <X> <Y> <Z>\n");
    _ = try out.write("\tSet center of geometry\n\n");

    _ = try out.write("        --set-com <X> <Y> <Z>\n");
    _ = try out.write("\tSet center of mass\n\n");

    _ = try out.write("        --align-principal-axes\n");
    _ = try out.write("\tAlign system's principal axes of inertia\n\n");

    _ = try out.write("        --version\n");
    _ = try out.write("\tPrint excutable version and exit\n\n");

    _ = try out.write("    -h, --help\n");
    _ = try out.write("\tDisplay this and exit\n\n");
}

const Arguments = struct {
    input: ?[]const u8 = null,
    output: ?[]const u8 = null,
    cog: ?[3]f64 = null,
    com: ?[3]f64 = null,
    align_axes: ?bool = null,
};

pub fn parse(allocator: *std.mem.Allocator) !Arguments {
    const out = io.getStdOut();
    var parsed_args = Arguments{};

    var args = std.os.argv;

    if (args.len == 1) {
        try displayUsage();
        exit(0);
    }

    var skip: u8 = 0;
    args_loop: for (args) |item, i| {
        if (skip > 0) {
            skip -= 1;
            continue;
        }

        var arg = item[0..std.mem.len(item)];

        if (eql(u8, "-h", arg) or eql(u8, "--help", arg)) {
            try displayUsage();
            exit(0);
        } else if (eql(u8, "--version", arg)) {
            _ = try out.write("mdtools " ++ version ++ "\n");
            exit(0);
        } else if (eql(u8, "-i", arg) or eql(u8, "--input", arg)) {
            if (i + 1 >= args.len) {
                _ = try out.write("Error: Argument missing for 'input' option.\n");
                exit(0);
            }
            if (eql(u8, args[i + 1][0..1], "-")) {
                _ = try out.write("Error: Argument missing for 'input' option.\n");
                exit(0);
            }
            if (parsed_args.input) |_| {
                _ = try out.write("Error: '-i' or '--input' appear more than one time.\n");
                exit(0);
            } else {
                parsed_args.input = args[i + 1][0..len(args[i + 1])];
                skip = 1;
            }
        } else if (eql(u8, "-o", arg) or eql(u8, "--output", arg)) {
            if (i + 1 >= args.len) {
                _ = try out.write("Error: Argument missing for 'output' option.\n");
                exit(0);
            }
            if (eql(u8, args[i + 1][0..1], "-")) {
                _ = try out.write("Error: Argument missing for 'output' option.\n");
                exit(0);
            }
            if (parsed_args.output) |_| {
                _ = try out.write("Error: '-o' or '--output' appear more than one time.\n");
                exit(0);
            } else {
                parsed_args.output = args[i + 1][0..len(args[i + 1])];
                skip = 1;
            }
        } else if (eql(u8, "--set-cog", arg)) {
            if (i + 3 >= args.len) {
                _ = try out.write("Error: Argument missing for '--set-cog' option.\n");
                exit(0);
            }
            if (parsed_args.cog) |_| {
                _ = try out.write("Error: '--set-cog' appears more than one time.\n");
                exit(0);
            } else {
                var center_of_geom = [_]f64{0} ** 3;
                center_of_geom[0] = fmt.parseFloat(f64, args[i + 1][0..len(args[i + 1])]) catch |_| {
                    _ = try out.write("Error: Invalid X argument for '--set-cog'.\n");
                    exit(0);
                };
                center_of_geom[1] = fmt.parseFloat(f64, args[i + 2][0..len(args[i + 2])]) catch |_| {
                    _ = try out.write("Error: Invalid Y argument for '--set-cog'.\n");
                    exit(0);
                };
                center_of_geom[2] = fmt.parseFloat(f64, args[i + 3][0..len(args[i + 3])]) catch |_| {
                    _ = try out.write("Error: Invalid Z argument for '--set-cog'.\n");
                    exit(0);
                };
                parsed_args.cog = center_of_geom;
                skip = 3;
            }
        } else if (eql(u8, "--set-com", arg)) {
            if (i + 3 >= args.len) {
                _ = try out.write("Error: Argument missing for '--set-com' option.\n");
                exit(0);
            }
            if (parsed_args.com) |_| {
                _ = try out.write("Error: '--set-com' appears more than one time.\n");
                exit(0);
            } else {
                var center_of_mass = [_]f64{0} ** 3;
                center_of_mass[0] = fmt.parseFloat(f64, args[i + 1][0..len(args[i + 1])]) catch |_| {
                    _ = try out.write("Error: Invalid X argument for '--set-com'.\n");
                    exit(0);
                };
                center_of_mass[1] = fmt.parseFloat(f64, args[i + 2][0..len(args[i + 2])]) catch |_| {
                    _ = try out.write("Error: Invalid Y argument for '--set-com'.\n");
                    exit(0);
                };
                center_of_mass[2] = fmt.parseFloat(f64, args[i + 3][0..len(args[i + 3])]) catch |_| {
                    _ = try out.write("Error: Invalid Z argument for '--set-com'.\n");
                    exit(0);
                };
                parsed_args.com = center_of_mass;
                skip = 3;
            }
        } else if (eql(u8, "--align-principal-axes", arg)) {
            if (parsed_args.align_axes) |_| {
                _ = try out.write("Error: '--align-principal-axes' appears more than one time.\n");
                exit(0);
            } else {
                parsed_args.align_axes = true;
            }
        } else if (i > 0) {
            var buf = try allocator.alloc(u8, 1024);
            const msg = try fmt.bufPrint(buf, "Error: Unknown argument '{s}'.\n", .{arg});
            _ = try out.write(msg);
            _ = try out.write("Try '-h' for more information.\n");
            exit(0);
        }
    }

    return parsed_args;
}
