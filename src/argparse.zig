const std = @import("std");
const io = std.io;
const fmt = std.fmt;
const eql = std.mem.eql;
const len = std.mem.len;
const exit = std.os.exit;
const vec = @import("./la.zig").vec3;

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

    _ = try out.write("        --align-principal-axes (X|Y|Z)\n");
    _ = try out.write("\tAlign system's principal axes of inertia along axis \n\n");

    _ = try out.write("        --version\n");
    _ = try out.write("\tPrint excutable version and exit\n\n");

    _ = try out.write("    -h, --help\n");
    _ = try out.write("\tDisplay this and exit\n\n");
}

const Axis = enum { X, Y, Z };
const Arguments = struct {
    input: []const u8 = null,
    output: []const u8 = null,
    cog: ?vec.Vec3(f64) = null,
    com: ?vec.Vec3(f64) = null,
    align_axes: ?Axis = null,
};

pub fn parse(allocator: *std.mem.Allocator) !Arguments {
    const out = io.getStdOut();

    var input: ?[]const u8 = null;
    var output: ?[]const u8 = null;
    var cog: ?vec.Vec3(f64) = null;
    var com: ?vec.Vec3(f64) = null;
    var align_axes: ?Axis = null;

    var args = std.os.argv;
    var skip: u8 = 0;

    args_loop: for (args) |item, i| {
        while (skip > 0) {
            skip -= 1;
            continue :args_loop;
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
            if (input) |_| {
                _ = try out.write("Error: '-i' or '--input' appear more than one time.\n");
                exit(0);
            } else {
                input = args[i + 1][0..len(args[i + 1])];
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
            if (output) |_| {
                _ = try out.write("Error: '-o' or '--output' appear more than one time.\n");
                exit(0);
            } else {
                output = args[i + 1][0..len(args[i + 1])];
                skip = 1;
            }
        } else if (eql(u8, "--set-cog", arg)) {
            if (i + 3 >= args.len) {
                _ = try out.write("Error: Argument missing for '--set-cog' option.\n");
                exit(0);
            }
            if (cog) |_| {
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
                cog = .{
                    .x = center_of_geom[0],
                    .y = center_of_geom[1],
                    .z = center_of_geom[2],
                };
                skip = 3;
            }
        } else if (eql(u8, "--set-com", arg)) {
            if (i + 3 >= args.len) {
                _ = try out.write("Error: Argument missing for '--set-com' option.\n");
                exit(0);
            }
            if (com) |_| {
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
                com = .{
                    .x = center_of_mass[0],
                    .y = center_of_mass[1],
                    .z = center_of_mass[2],
                };
                skip = 3;
            }
        } else if (eql(u8, "--align-principal-axes", arg)) {
            if (i + 1 >= args.len) {
                _ = try out.write("Error: Argument missing for '--align-principal-axes' option.\n");
                exit(0);
            }
            if (eql(u8, args[i + 1][0..1], "-")) {
                _ = try out.write("Error: Argument missing for '--align-principal-axes' option.\n");
                exit(0);
            }
            if (align_axes) |_| {
                _ = try out.write("Error: '--align-principal-axes' appears more than one time.\n");
                exit(0);
            } else {
                const ax = args[i + 1][0..len(args[i + 1])];
                if (eql(u8, ax, "X")) {
                    align_axes = .X;
                } else if (eql(u8, ax, "Y")) {
                    align_axes = .Y;
                } else if (eql(u8, ax, "Z")) {
                    align_axes = .Z;
                } else {
                    _ = try out.write("Error: Invalid argument for '--align-principal-axes'.\n");
                }
                skip = 1;
            }
        } else if (i > 0) {
            var buf = try allocator.alloc(u8, 1024);
            const msg = try fmt.bufPrint(buf, "Error: Unknown argument '{s}'.\n", .{arg});
            _ = try out.write(msg);
            _ = try out.write("Try '-h' for more information.\n");
            exit(0);
        }
    }

    return Arguments{
        .input = if (input) |input_file| input_file else {
            _ = try out.write("Error: Missing input file.\n");
            exit(0);
        },
        .output = if (output) |output_file| output_file else "out",
        .cog = cog,
        .com = com,
        .align_axes = align_axes,
    };
}
