const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const Allocator = mem.Allocator;

const Pdb = struct {
    allocator: *Allocator,

    const Self = @This();

    pub fn init(allocator: *Allocator) Self {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.deinit();
    }

    const WriteError = error{ OutOfMemory, InvalidRecord };

    pub fn write(self: *Self, bytes: []const u8) WriteError!void {
        const lf = mem.indexOf(u8, bytes, "\n");
        const line = if (lf) |i| bytes[0..i] else bytes;
        const data = mem.trim(u8, line, " ");

        if (data.len == 0) {
            return;
        } else {
            // TODO
            // const record = try parseRecord(data);
            // try self.records.append(record);
        }
    }
};

test "Open PDB file" {
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    var tmp_pdb = try tmp.dir.createFile("foo.pdb", .{ .read = true });

    var pdb = Pdb.init(testing.allocator);
    try pdb.write("\n");
}
