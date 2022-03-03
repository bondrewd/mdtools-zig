const std = @import("std");
const Allocator = std.mem.Allocator;

pub const ProgressBar = struct {
    fill: []const u8,
    r_sep: []const u8,
    l_sep: []const u8,
    blocks: []const []const u8,
    length: u32,

    const Self = @This();

    const ProgressBarConfig = struct {
        fill: ?[]const u8 = null,
        r_sep: ?[]const u8 = null,
        l_sep: ?[]const u8 = null,
        blocks: ?[]const []const u8 = null,
        length: ?u8 = null,
    };

    pub fn init(config: ProgressBarConfig) Self {
        return .{
            .fill = config.fill orelse "▒",
            .r_sep = config.r_sep orelse "|",
            .l_sep = config.r_sep orelse "|",
            .blocks = config.blocks orelse &[_][]const u8{ " ", "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█" },
            .length = config.length orelse 25,
        };
    }

    pub fn displayProgressWriter(self: Self, value: u32, min: u32, max: u32, writer: anytype) !void {
        var v = value;
        v = if (v > min) v else min;
        v = if (v < max) v else max;

        const n = @intToFloat(f32, self.blocks.len - 1);
        const p = @intToFloat(f32, v - min) / @intToFloat(f32, max - min);
        const l = @floor(p * @intToFloat(f32, self.length));
        const x = @floatToInt(u32, l);
        const y = @floatToInt(u32, @floor(n * (l - @intToFloat(f32, x))));

        // Carriage return
        try writer.writeByte('\r');
        // Write left part
        try writer.writeAll(self.l_sep);
        // Write middle part
        var i: usize = 0;
        while (i < self.length) : (i += 1) {
            if (i < x) {
                try writer.writeAll(self.blocks[self.blocks.len - 1]);
            } else if (i == x) {
                try writer.writeAll(self.blocks[y]);
            } else {
                try writer.writeAll(self.fill);
            }
        }
        // Write right part
        try writer.writeAll(self.r_sep);
        // Write percentage
        try writer.print(" {d:6.2}%", .{p * 100});
        // Write new line
        if (v == max) try writer.writeByte('\n');
    }
};
