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
    input: []const u8 = null,
    output: []const u8 = null,
};

pub fn parse(allocator: *std.mem.Allocator) !Arguments {
    const out = getStdOut();

    var input: ?[]const u8 = null;
    var output: ?[]const u8 = null;

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
        }
    }

    return Arguments{
        .input = if (input) |input_file| input_file else {
            _ = try out.write("Error: Missing input file.\n");
            exit(0);
        },
        .output = if (output) |output_file| output_file else "out",
    };
}
