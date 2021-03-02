const std = @import("std");

pub const TakesValue = enum {
    No,
    One,
    Many,
};

pub const Argument = struct {
    short: ?[]const u8 = null,
    long: ?[]const u8 = null,
    meta: ?[]const u8 = null,
    name: []const u8,
    help: []const u8,
    takes_value: TakesValue = .No,
    default_value: ?[]const []const u8 = null,
};

pub const Parser = struct {
    arguments: std.ArrayList(Argument),
    allocator: *std.mem.Allocator,
    bin_name: ?[]const u8 = null,
    version: ?[]const u8 = null,
    description: ?[]const u8 = null,

    const Self = @This();

    pub fn init(allocator: *std.mem.Allocator) Self {
        return Self{
            .arguments = std.ArrayList(Argument).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.arguments.deinit();
    }

    pub fn addBinName(self: *Self, bin_name: []const u8) Self {
        self.bin_name = bin_name;
        return self.*;
    }

    pub fn addVersion(self: *Self, version: []const u8) Self {
        self.version = version;
        return self.*;
    }

    pub fn addDescription(self: *Self, description: []const u8) Self {
        self.description = description;
        return self.*;
    }

    pub fn addArgument(self: *Self, argument: Argument) Self {
        self.arguments.append(argument) catch |err| {
            _ = std.io.getStdErr().write("Couldn't create parser") catch unreachable;
        };

        return self.*;
    }

    pub fn displayUsage(self: Self) !void {
        const stdout = std.io.getStdOut();
        var buf = try self.allocator.alloc(u8, 1024);
        defer self.allocator.free(buf);
        var line: []u8 = undefined;
        var short: []const u8 = undefined;
        var long: []const u8 = undefined;
        var meta: []const u8 = undefined;

        // Display program name and version
        if (self.bin_name) |bin_name| {
            const version = self.version orelse "";
            line = try std.fmt.bufPrint(buf, "{s} {s}\n", .{ bin_name, version });
            _ = try stdout.write(line);
        }

        // Display program about
        if (self.description) |description| {
            line = try std.fmt.bufPrint(buf, "{s}\n", .{description});
            _ = try stdout.write(line);
        }

        _ = try stdout.write("\n");

        // Display usage
        if (self.bin_name) |bin_name| {
            _ = try stdout.write("USAGE:\n");
            line = try std.fmt.bufPrint(buf, "./{s}", .{bin_name});

            for (self.arguments.items) |arg| {
                if (arg.short != null or arg.long != null) {
                    line = try std.fmt.bufPrint(buf, "{s} [OPTIONS]", .{line});
                    break;
                }
            }

            for (self.arguments.items) |arg| {
                if (arg.short == null and arg.long == null) {
                    meta = arg.meta orelse "ARG";
                    line = try std.fmt.bufPrint(buf, "{s} <{s}>", .{ line, meta });
                }
            }

            line = try std.fmt.bufPrint(buf, "{s}\n", .{line});
            _ = try stdout.write(line);
        }

        _ = try stdout.write("\n");

        // Display optional arguments
        _ = try stdout.write("OPTIONS\n");
        for (self.arguments.items) |arg| {
            if (arg.short != null or arg.long != null) {
                short = arg.short orelse "";
                long = arg.long orelse "";
                line = try std.fmt.bufPrint(buf, "    {s:<2}, {s}\n", .{ short, long });
                _ = try stdout.write(line);
                line = try std.fmt.bufPrint(buf, "\t{s}\n", .{arg.help});
                _ = try stdout.write(line);
            }
        }

        _ = try stdout.write("\n");

        // Display positional arguments
        _ = try stdout.write("ARGS\n");
        for (self.arguments.items) |arg| {
            if (arg.short == null and arg.long == null) {
                line = try std.fmt.bufPrint(buf, "\t<{s}>\n", .{arg.meta});
                _ = try stdout.write(line);
                line = try std.fmt.bufPrint(buf, "\t{s}\n", .{arg.help});
                _ = try stdout.write(line);
            }
        }

        _ = try stdout.write("\n");
    }
};
