const std = @import("std");
const eql = std.mem.eql;
const len = std.mem.len;
const bufPrint = std.fmt.bufPrint;
const exit = std.os.exit;
const getStdOut = std.io.getStdOut;

const version = "0.1.0";

pub fn displayUsage() !void {
    const out = std.io.getStdOut();
    _ = try out.write("mdtools " ++ version ++ "\n\n");
    _ = try out.write("Tools for manipulating MD related files.\n\n");

    _ = try out.write("USAGE\n");
    _ = try out.write("./mdtools [OPTION]\n\n");

    _ = try out.write("OPTIONS\n");
    _ = try out.write("    -i, --input <FILE>\n");
    _ = try out.write("\tInput file name\n\n");

    _ = try out.write("    -o, --output <NAME>\n");
    _ = try out.write("\tOutput file name (Default: out)\n\n");

    _ = try out.write("        --version\n");
    _ = try out.write("\tPrint excutable version and exit\n\n");

    _ = try out.write("    -h, --help\n");
    _ = try out.write("\tDisplay this and exit\n\n");
}

const Arguments = struct {
    input: ?[]const u8 = null,
    output: ?[]const u8 = null,
    fix_numeration: bool = false,
};

pub fn parse(allocator: *std.mem.Allocator) !Arguments {
    const out = getStdOut();
    var arguments = Arguments{};
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
                _ = try out.write("Argument missing for 'input' option\n");
                exit(0);
            }
            if (eql(u8, args[i + 1][0..1], "-")) {
                _ = try out.write("Argument missing for 'input' option\n");
                exit(0);
            }
            if (arguments.input) |_| {
                _ = try out.write("'-i' or '--input' appear more than one time\n");
                exit(0);
            } else {
                arguments.input = args[i + 1][0..len(args[i + 1])];
                skip = 1;
            }
        } else if (eql(u8, "-o", arg) or eql(u8, "--output", arg)) {
            if (i + 1 >= args.len) {
                _ = try out.write("Argument missing for 'output' option\n");
                exit(0);
            }
            if (eql(u8, args[i + 1][0..1], "-")) {
                _ = try out.write("Argument missing for 'output' option\n");
                exit(0);
            }
            if (arguments.output) |_| {
                _ = try out.write("'-o' or '--output' appear more than one time\n");
                exit(0);
            } else {
                arguments.output = args[i + 1][0..len(args[i + 1])];
                skip = 1;
            }
        }

        //std.debug.print("i: {d}\targ: {s}\n", .{ i, arg });
    }
    //std.debug.print("input: {s}\n", .{arguments.input});
    //std.debug.print("output: {s}\n", .{arguments.output});
    return arguments;
}
