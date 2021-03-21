const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
const math = std.math;
const testing = std.testing;

pub const AtomRecord = struct {
    atom_id: ?u64 = null,
    atom_name: ?[4]u8 = null,
    alt_loc: ?u8 = null,
    mol_name: ?[3]u8 = null,
    chain_id: ?u8 = null,
    mol_id: ?u64 = null,
    i_code: ?u8 = null,
    x: ?f32 = null,
    y: ?f32 = null,
    z: ?f32 = null,
    occupancy: ?f32 = null,
    factor: ?f32 = null,
    element: ?[2]u8 = null,
    charge: ?[2]u8 = null,

    const Self = @This();

    const ParseError = error{ EmptyLine, InvalidRecord };

    pub fn parse(bytes: []const u8) ParseError!Self {
        if (bytes.len == 0) return error.EmptyLine;

        var atom_record: AtomRecord = undefined;

        if (bytes.len >= 6 and mem.eql(u8, bytes[0..6], "ATOM  ")) {
            atom_record = AtomRecord{};
        } else {
            return error.InvalidRecord;
        }

        if (bytes.len >= 11) {
            const data = mem.trim(u8, bytes[6..11], " ");
            atom_record.atom_id = fmt.parseUnsigned(u64, data, 10) catch |_| null;
        } else {
            return atom_record;
        }

        if (bytes.len >= 16) {
            const data = bytes[12..16];
            if (!mem.allEqual(u8, data, ' ')) atom_record.atom_name = data.*;
        } else {
            return atom_record;
        }

        if (bytes.len >= 17) {
            if (bytes[16] != ' ') atom_record.alt_loc = bytes[16];
        } else {
            return atom_record;
        }

        if (bytes.len >= 20) {
            const data = bytes[17..20];
            if (!mem.allEqual(u8, data, ' ')) atom_record.mol_name = data.*;
        } else {
            return atom_record;
        }

        if (bytes.len >= 22) {
            if (bytes[21] != ' ') atom_record.chain_id = bytes[21];
        } else {
            return atom_record;
        }

        if (bytes.len >= 26) {
            const data = mem.trim(u8, bytes[22..26], " ");
            atom_record.mol_id = fmt.parseUnsigned(u64, data, 10) catch |_| null;
        } else {
            return atom_record;
        }

        if (bytes.len >= 27) {
            if (bytes[26] != ' ') atom_record.i_code = bytes[26];
        } else {
            return atom_record;
        }

        if (bytes.len >= 38) {
            const data = mem.trim(u8, bytes[30..38], " ");
            atom_record.x = fmt.parseFloat(f32, data) catch |_| null;
        } else {
            return atom_record;
        }

        if (bytes.len >= 46) {
            const data = mem.trim(u8, bytes[38..46], " ");
            atom_record.y = fmt.parseFloat(f32, data) catch |_| null;
        } else {
            return atom_record;
        }

        if (bytes.len >= 54) {
            const data = mem.trim(u8, bytes[46..54], " ");
            atom_record.z = fmt.parseFloat(f32, data) catch |_| null;
        } else {
            return atom_record;
        }

        if (bytes.len >= 60) {
            const data = mem.trim(u8, bytes[54..60], " ");
            atom_record.occupancy = fmt.parseFloat(f32, data) catch |_| null;
        } else {
            return atom_record;
        }

        if (bytes.len >= 66) {
            const data = mem.trim(u8, bytes[60..66], " ");
            atom_record.factor = fmt.parseFloat(f32, data) catch |_| null;
        } else {
            return atom_record;
        }

        if (bytes.len >= 78) {
            const data = bytes[76..78];
            if (!mem.allEqual(u8, data, ' ')) atom_record.element = data.*;
        } else {
            return atom_record;
        }

        if (bytes.len >= 80) {
            const data = bytes[78..80];
            if (!mem.allEqual(u8, data, ' ')) atom_record.charge = data.*;
        } else {
            return atom_record;
        }

        return atom_record;
    }

    pub fn bufPrint(self: Self, buffer: []u8) fmt.BufPrintError![]u8 {
        var line: []u8 = undefined;

        line = try fmt.bufPrint(buffer, "ATOM  ", .{});

        if (self.atom_id) |atom_id| {
            line = try fmt.bufPrint(buffer, "{s: <6}{d:>5}", .{ line, atom_id });
        } else {
            line = try fmt.bufPrint(buffer, "{s: <6}     ", .{line});
        }

        if (self.atom_name) |atom_name| {
            line = try fmt.bufPrint(buffer, "{s: <12}{s: ^4}", .{ line, atom_name });
        } else {
            line = try fmt.bufPrint(buffer, "{s: <12}    ", .{line});
        }

        if (self.alt_loc) |alt_loc| {
            line = try fmt.bufPrint(buffer, "{s: <16}{c}", .{ line, alt_loc });
        } else {
            line = try fmt.bufPrint(buffer, "{s: <16} ", .{line});
        }

        if (self.mol_name) |mol_name| {
            line = try fmt.bufPrint(buffer, "{s: <17}{s: >3}", .{ line, mol_name });
        } else {
            line = try fmt.bufPrint(buffer, "{s: <17}   ", .{line});
        }

        if (self.chain_id) |chain_id| {
            line = try fmt.bufPrint(buffer, "{s: <21}{c}", .{ line, chain_id });
        } else {
            line = try fmt.bufPrint(buffer, "{s: <21} ", .{line});
        }

        if (self.mol_id) |mol_id| {
            line = try fmt.bufPrint(buffer, "{s: <22}{d: >4}", .{ line, mol_id });
        } else {
            line = try fmt.bufPrint(buffer, "{s: <22}    ", .{line});
        }

        if (self.i_code) |i_code| {
            line = try fmt.bufPrint(buffer, "{s: <26}{c}", .{ line, i_code });
        } else {
            line = try fmt.bufPrint(buffer, "{s: <26} ", .{line});
        }

        if (self.x) |x| {
            line = try fmt.bufPrint(buffer, "{s: <30}{d: >8.3}", .{ line, x });
        } else {
            line = try fmt.bufPrint(buffer, "{s: <30}        ", .{line});
        }

        if (self.y) |y| {
            line = try fmt.bufPrint(buffer, "{s: <38}{d: >8.3}", .{ line, y });
        } else {
            line = try fmt.bufPrint(buffer, "{s: <38}        ", .{line});
        }

        if (self.z) |z| {
            line = try fmt.bufPrint(buffer, "{s: <46}{d: >8.3}", .{ line, z });
        } else {
            line = try fmt.bufPrint(buffer, "{s: <46}        ", .{line});
        }

        if (self.occupancy) |occupancy| {
            line = try fmt.bufPrint(buffer, "{s: <54}{d: >6.2}", .{ line, occupancy });
        } else {
            line = try fmt.bufPrint(buffer, "{s: <54}      ", .{line});
        }

        if (self.factor) |factor| {
            line = try fmt.bufPrint(buffer, "{s: <60}{d: >6.2}", .{ line, factor });
        } else {
            line = try fmt.bufPrint(buffer, "{s: <60}      ", .{line});
        }

        if (self.element) |element| {
            line = try fmt.bufPrint(buffer, "{s: <76}{s: >2}", .{ line, element });
        } else {
            line = try fmt.bufPrint(buffer, "{s: <76}  ", .{line});
        }

        if (self.charge) |charge| {
            line = try fmt.bufPrint(buffer, "{s: <78}{s: >2}", .{ line, charge });
        } else {
            line = try fmt.bufPrint(buffer, "{s: <78}  ", .{line});
        }

        line = try fmt.bufPrint(buffer, "{s: <80}\n", .{line});

        return line;
    }

    pub fn hasMissingField(self: Self) bool {
        var has_missing: bool = false;

        has_missing = has_missing or self.atom_id == null;
        has_missing = has_missing or self.atom_name == null;
        has_missing = has_missing or self.alt_loc == null;
        has_missing = has_missing or self.mol_name == null;
        has_missing = has_missing or self.chain_id == null;
        has_missing = has_missing or self.mol_id == null;
        has_missing = has_missing or self.i_code == null;
        has_missing = has_missing or self.x == null;
        has_missing = has_missing or self.y == null;
        has_missing = has_missing or self.z == null;
        has_missing = has_missing or self.occupancy == null;
        has_missing = has_missing or self.factor == null;
        has_missing = has_missing or self.element == null;
        has_missing = has_missing or self.charge == null;

        return has_missing;
    }

    pub fn hasMissingPositions(self: Self) bool {
        var has_missing: bool = false;

        has_missing = has_missing or self.x == null;
        has_missing = has_missing or self.y == null;
        has_missing = has_missing or self.z == null;

        return has_missing;
    }
};

test "Test parsing an atom record" {
    //                     1         2         3         4         5         6         7         8
    //            12345678901234567890123456789012345678901234567890123456789012345678901234567890
    const line = "ATOM      1  N  aMET A   1b      1.498   2.919   4.288  1.00 10.65           N-1";
    var atom_record = try AtomRecord.parse(line);

    const eps = math.epsilon(f32);
    testing.expect(atom_record.atom_id.? == 1);
    testing.expectEqualStrings(atom_record.atom_name.?[0..], " N  ");
    testing.expect(atom_record.alt_loc.? == 'a');
    testing.expectEqualStrings(atom_record.mol_name.?[0..], "MET");
    testing.expect(atom_record.chain_id.? == 'A');
    testing.expect(atom_record.mol_id.? == 1);
    testing.expect(atom_record.i_code.? == 'b');
    testing.expectApproxEqAbs(atom_record.x.?, 1.498, eps);
    testing.expectApproxEqAbs(atom_record.y.?, 2.919, eps);
    testing.expectApproxEqAbs(atom_record.z.?, 4.288, eps);
    testing.expectApproxEqAbs(atom_record.occupancy.?, 1.00, eps);
    testing.expectApproxEqAbs(atom_record.factor.?, 10.65, eps);
    testing.expectEqualStrings(atom_record.element.?[0..], " N");
    testing.expectEqualStrings(atom_record.charge.?[0..], "-1");
}

test "Test parsing an incomplete atom record" {
    //                     1         2         3         4         5         6         7         8
    //            12345678901234567890123456789012345678901234567890123456789012345678901234567890
    const line = "ATOM                                                                            ";
    var atom_record = try AtomRecord.parse(line);

    testing.expect(atom_record.atom_id == null);
    testing.expect(atom_record.atom_name == null);
    testing.expectEqual(atom_record.alt_loc, null);
    testing.expectEqual(atom_record.mol_name, null);
    testing.expectEqual(atom_record.chain_id, null);
    testing.expectEqual(atom_record.mol_id, null);
    testing.expectEqual(atom_record.i_code, null);
    testing.expectEqual(atom_record.x, null);
    testing.expectEqual(atom_record.y, null);
    testing.expectEqual(atom_record.z, null);
    testing.expectEqual(atom_record.occupancy, null);
    testing.expectEqual(atom_record.factor, null);
    testing.expectEqual(atom_record.element, null);
    testing.expectEqual(atom_record.charge, null);
}

test "Test parsing a short atom record" {
    //                     1         2         3         4         5         6         7         8
    //            12345678901234567890123456789012345678901234567890123456789012345678901234567890
    const line = "ATOM  ";
    var atom_record = try AtomRecord.parse(line);

    testing.expect(atom_record.atom_id == null);
    testing.expect(atom_record.atom_name == null);
    testing.expectEqual(atom_record.alt_loc, null);
    testing.expectEqual(atom_record.mol_name, null);
    testing.expectEqual(atom_record.chain_id, null);
    testing.expectEqual(atom_record.mol_id, null);
    testing.expectEqual(atom_record.i_code, null);
    testing.expectEqual(atom_record.x, null);
    testing.expectEqual(atom_record.y, null);
    testing.expectEqual(atom_record.z, null);
    testing.expectEqual(atom_record.occupancy, null);
    testing.expectEqual(atom_record.factor, null);
    testing.expectEqual(atom_record.element, null);
    testing.expectEqual(atom_record.charge, null);
}

test "Test print atom record to buffer" {
    const record = "ATOM    542  OH aPRO G    p     -1.000   2.000  -3.150  3.00  1.00          Ba-1\n";
    const atom_record = try AtomRecord.parse(record);

    var buffer = try testing.allocator.alloc(u8, 81);
    defer testing.allocator.free(buffer);

    const line = try atom_record.bufPrint(buffer);
    testing.expectEqualStrings(line, record);
}
