const std = @import("std");
const io = std.io;
const fmt = std.fmt;
const eql = std.mem.eql;
const len = std.mem.len;
const exit = std.os.exit;
const ansi = @import("ansi.zig");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const TypeInfo = std.builtin.TypeInfo;
const StructField = TypeInfo.StructField;
const Declaration = TypeInfo.Declaration;

const reset = ansi.reset;
const bold = ansi.txt_bold;
const blue = ansi.fg_blue;
const green = ansi.fg_green;
const yellow = ansi.fg_yellow;

const ParserConfig = struct {
    bin_name: []const u8,
    bin_info: []const u8,
    bin_usage: []const u8,
    bin_version: struct { major: u8, minor: u8, patch: u8 },
};

const ParserOption = struct {
    name: []const u8,
    long: ?[]const u8 = null,
    short: ?[]const u8 = null,
    metavar: ?[]const u8 = null,
    description: []const u8,
    argument_type: type = bool,
    takes: enum { None, One, Many } = .None,
};

fn ArgumentParser(comptime config: ParserConfig, comptime options: []const ParserOption) type {
    return struct {
        const Self = @This();

        pub fn displayUsage() !void {
            const stdout = io.getStdOut().writer();

            // binary version
            const name = config.bin_name;
            const major = config.bin_version.major;
            const minor = config.bin_version.minor;
            const patch = config.bin_version.patch;
            try stdout.print(bold ++ green ++ "{s}" ++ blue ++ " {d}.{d}.{d}\n\n" ++ reset, .{ name, major, minor, patch });

            // binary info
            try stdout.writeAll(config.bin_info ++ "\n\n");

            // bin usage
            try stdout.writeAll(bold ++ yellow ++ "USAGE\n" ++ reset);
            try stdout.writeAll("    " ++ config.bin_usage ++ "\n\n");

            // bin options
            try stdout.writeAll(bold ++ yellow ++ "OPTIONS\n" ++ reset);
            inline for (options) |option| {
                const long = option.long orelse "";
                const short = option.short orelse "  ";
                const metavar = option.metavar orelse "";
                const separator = if (option.short != null) (if (option.long != null) ", " else "") else "  ";
                if (option.short == null and option.long == null) @compileError("Option must have defined at least short or long");

                try stdout.writeAll(bold ++ green ++ "    " ++ short ++ separator ++ long ++ " " ++ metavar ++ reset);
                try stdout.writeAll("\n\t" ++ option.description ++ "\n\n");
            }
        }

        const ParserResult = blk: {
            // Struct fields
            var fields: [options.len]StructField = undefined;
            inline for (options) |option, i| {
                fields[i] = .{
                    .name = option.name,
                    .field_type = switch (option.takes) {
                        .None => bool,
                        .One => ?option.argument_type,
                        .Many => ArrayList(option.argument_type),
                    },
                    .default_value = null,
                    .is_comptime = false,
                    .alignment = @alignOf(option.argument_type),
                };
            }

            // Struct declarations
            var decls: [0]Declaration = .{};

            break :blk @Type(TypeInfo{ .Struct = .{
                .layout = .Auto,
                .fields = &fields,
                .decls = &decls,
                .is_tuple = false,
            } });
        };

        pub fn parse(allocator: *Allocator) !ParserResult {
            // Initialize parser result
            var parsed_args: ParserResult = undefined;
            inline for (options) |option| {
                @field(parsed_args, option.name) = switch (option.takes) {
                    .None => false,
                    .One => null,
                    .Many => ArrayList(option.argument_type).init(allocator),
                };
            }

            // Get arguments
            var arguments = std.os.argv;
            if (arguments.len == 1) return parsed_args;

            // Parse arguments
            var i: usize = 1;
            argument_loop: while (i < arguments.len) : (i += 1) {
                // Get slice from null terminated string
                const arg = arguments[i][0..len(arguments[i])];

                // Iterate over all the options
                inline for (options) |option| {
                    if (eql(u8, arg, option.short orelse "") or eql(u8, arg, option.long orelse "")) {
                        switch (option.takes) {
                            .None => @field(parsed_args, option.name) = true,
                            .One => {
                                if (arguments.len <= i + 1) return error.MissingArgument;
                                const next_arg = arguments[i + 1][0..len(arguments[i + 1])];
                                switch (@typeInfo(option.argument_type)) {
                                    .Int => @field(parsed_args, option.name) = try fmt.parseInt(option.argument_type, next_arg),
                                    .Float => @field(parsed_args, option.name) = try fmt.parseFloat(option.argument_type, next_arg),
                                    .Pointer => @field(parsed_args, option.name) = next_arg,
                                    else => unreachable,
                                }
                                i += 1;
                            },
                            .Many => {
                                var j: usize = 1;
                                search_loop: while (arguments.len > i + j) : (j += 1) {
                                    const next_arg = arguments[i + j][0..len(arguments[i + j])];
                                    inline for (options) |opt| {
                                        if (eql(u8, next_arg, option.short orelse "") or eql(u8, next_arg, option.long orelse "")) break :search_loop;
                                    }
                                    switch (@typeInfo(option.argument_type)) {
                                        .Int => try @field(parsed_args, option.name).append(try fmt.parseInt(option.argument_type, next_arg)),
                                        .Float => try @field(parsed_args, option.name).append(try fmt.parseFloat(option.argument_type, next_arg)),
                                        .Pointer => try @field(parsed_args, option.name).append(next_arg),
                                        else => unreachable,
                                    }
                                }
                                i = i + j;
                            },
                        }
                        continue :argument_loop;
                    }
                }

                return error.UnknownArgument;
            }

            return parsed_args;
        }

        pub fn deinit(args: ParserResult) void {
            inline for (options) |option| {
                switch (option.takes) {
                    .Many => @field(args, option.name).deinit(),
                    else => {},
                }
            }
        }
    };
}

pub const Parser = ArgumentParser(.{
    .bin_name = "mdtools",
    .bin_info = "Tools for manipulating Molecular Dynamics (MD) files.",
    .bin_usage = "./mdtools OPTION [OPTION...]",
    .bin_version = .{ .major = 0, .minor = 1, .patch = 0 },
}, &[_]ParserOption{
    .{
        .name = "input",
        .long = "--input",
        .short = "-i",
        .description = "Input file name",
        .metavar = "<FILE>",
        .argument_type = []const u8,
        .takes = .One,
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
        .metavar = "<FILE>",
        .argument_type = []const u8,
        .takes = .One,
    },
    .{
        .name = "translate_com",
        .long = "--translate-com",
        .description = "Translate center of mass",
        .metavar = "<X> <Y> <Y>",
        .argument_type = f32,
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
