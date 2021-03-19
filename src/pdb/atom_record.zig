const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
const math = std.math;
const testing = std.testing;

pub const AtomRecord = struct {
    atom_id: ?u32 = null,
    atom_name: ?[]const u8 = null,
    alt_loc: ?[]const u8 = null,
    mol_name: ?[]const u8 = null,
    chain_id: ?[]const u8 = null,
    mol_id: ?u32 = null,
    i_code: ?[]const u8 = null,
    x: ?f64 = null,
    y: ?f64 = null,
    z: ?f64 = null,
    occupancy: ?f64 = null,
    factor: ?f64 = null,
    element: ?[]const u8 = null,
    charge: ?f64 = null,

    const Self = @This();

    pub fn hasMissingCoordinates(self: Self) bool {
        return if (self.x == null or self.y == null or self.z == null) true else false;
    }

    pub fn parseAtomRecord(slice: []const u8) !Self {
        if (slice.len == 0) return error.EmptyLine;
        if (slice.len > 6 and mem.eql(u8, slice[0..6], "ATOM  ")) {
            var val = mem.trim(u8, slice[6..11], " ");
            const atom_id = fmt.parseUnsigned(u32, val, 10) catch |_| null;

            val = mem.trim(u8, slice[12..16], " ");
            const atom_name = if (val.len > 0) val else null;

            val = mem.trim(u8, slice[16..17], " ");
            const alt_loc = if (val.len > 0) val else null;

            val = mem.trim(u8, slice[17..20], " ");
            const mol_name = if (val.len > 0) val else null;

            val = mem.trim(u8, slice[21..22], " ");
            const chain_id = if (val.len > 0) val else null;

            val = mem.trim(u8, slice[22..26], " ");
            const mol_id = fmt.parseUnsigned(u32, val, 10) catch |_| null;

            val = mem.trim(u8, slice[26..27], " ");
            const i_code = if (val.len > 0) val else null;

            val = mem.trim(u8, slice[30..38], " ");
            const x = fmt.parseFloat(f64, val) catch |_| null;

            val = mem.trim(u8, slice[38..46], " ");
            const y = fmt.parseFloat(f64, val) catch |_| null;

            val = mem.trim(u8, slice[46..54], " ");
            const z = fmt.parseFloat(f64, val) catch |_| null;

            val = mem.trim(u8, slice[54..60], " ");
            const occupancy = fmt.parseFloat(f64, val) catch |_| null;

            val = mem.trim(u8, slice[60..66], " ");
            const factor = fmt.parseFloat(f64, val) catch |_| null;

            val = mem.trim(u8, slice[76..78], " ");
            const element = if (val.len > 0) val else null;

            val = mem.trim(u8, slice[78..80], " ");
            const charge = fmt.parseFloat(f64, val) catch |_| null;

            return Self{
                .atom_id = atom_id,
                .atom_name = atom_name,
                .alt_loc = alt_loc,
                .mol_name = mol_name,
                .chain_id = chain_id,
                .mol_id = mol_id,
                .i_code = i_code,
                .x = x,
                .y = y,
                .z = z,
                .occupancy = occupancy,
                .factor = factor,
                .element = element,
                .charge = charge,
            };
        } else {
            return error.BadRecordIdentifier;
        }
    }

    pub fn bufPrintAtomRecord(self: Self, buf: []u8) ![]u8 {
        if (buf.len < 81) return error.BufferTooSmall;
        var line: []u8 = undefined;

        if (self.atom_id) |atom_id| {
            line = try fmt.bufPrint(buf, "ATOM  {d:>5}", .{atom_id});
        } else {
            line = try fmt.bufPrint(buf, "ATOM       ", .{});
        }

        if (self.atom_name) |atom_name| {
            line = try fmt.bufPrint(buf, "{s: <12}{s: ^4}", .{ line, atom_name });
        } else {
            line = try fmt.bufPrint(buf, "{s: <12}    ", .{line});
        }

        if (self.alt_loc) |alt_loc| {
            line = try fmt.bufPrint(buf, "{s: <16}{s:1}", .{ line, alt_loc });
        } else {
            line = try fmt.bufPrint(buf, "{s: <16} ", .{line});
        }

        if (self.mol_name) |mol_name| {
            line = try fmt.bufPrint(buf, "{s: <17}{s: >3}", .{ line, mol_name });
        } else {
            line = try fmt.bufPrint(buf, "{s: <17}   ", .{line});
        }

        if (self.chain_id) |chain_id| {
            line = try fmt.bufPrint(buf, "{s: <21}{s:1}", .{ line, chain_id });
        } else {
            line = try fmt.bufPrint(buf, "{s: <21} ", .{line});
        }

        if (self.mol_id) |mol_id| {
            line = try fmt.bufPrint(buf, "{s: <22}{d: >4}", .{ line, mol_id });
        } else {
            line = try fmt.bufPrint(buf, "{s: <22}    ", .{line});
        }

        if (self.i_code) |i_code| {
            line = try fmt.bufPrint(buf, "{s: <26}{s:1}", .{ line, i_code });
        } else {
            line = try fmt.bufPrint(buf, "{s: <26} ", .{line});
        }

        if (self.x) |x| {
            line = try fmt.bufPrint(buf, "{s: <30}{d: >8.3}", .{ line, x });
        } else {
            line = try fmt.bufPrint(buf, "{s: <30}        ", .{line});
        }

        if (self.y) |y| {
            line = try fmt.bufPrint(buf, "{s: <38}{d: >8.3}", .{ line, y });
        } else {
            line = try fmt.bufPrint(buf, "{s: <38}        ", .{line});
        }

        if (self.z) |z| {
            line = try fmt.bufPrint(buf, "{s: <46}{d: >8.3}", .{ line, z });
        } else {
            line = try fmt.bufPrint(buf, "{s: <46}        ", .{line});
        }

        if (self.occupancy) |occupancy| {
            line = try fmt.bufPrint(buf, "{s: <54}{d: >6.2}", .{ line, occupancy });
        } else {
            line = try fmt.bufPrint(buf, "{s: <54}      ", .{line});
        }

        if (self.factor) |factor| {
            line = try fmt.bufPrint(buf, "{s: <60}{d: >6.2}", .{ line, factor });
        } else {
            line = try fmt.bufPrint(buf, "{s: <60}      ", .{line});
        }

        if (self.element) |element| {
            line = try fmt.bufPrint(buf, "{s: <76}{s: >2}", .{ line, element });
        } else {
            line = try fmt.bufPrint(buf, "{s: <76}  ", .{line});
        }

        if (self.charge) |charge| {
            line = try fmt.bufPrint(buf, "{s: <78}{d: >2.0}", .{ line, charge });
        } else {
            line = try fmt.bufPrint(buf, "{s: <78}  ", .{line});
        }

        line = try fmt.bufPrint(buf, "{s: <80}\n", .{line});

        return line;
    }
};

test "Test parse atom record" {
    const line = "ATOM      1  N   MET A   1       1.498   2.919   4.288  1.00 10.65           N  ";
    var atom_record = try AtomRecord.parseAtomRecord(line);

    testing.expect(atom_record.atom_id.? == 1);
    testing.expectEqualStrings(atom_record.atom_name.?, "N");
    testing.expect(atom_record.alt_loc == null);
    testing.expectEqualStrings(atom_record.mol_name.?, "MET");
    testing.expectEqualStrings(atom_record.chain_id.?, "A");
    testing.expect(atom_record.mol_id.? == 1);
    testing.expect(atom_record.i_code == null);
    testing.expectWithinEpsilon(atom_record.x.?, 1.498, math.epsilon(f64));
    testing.expectWithinEpsilon(atom_record.y.?, 2.919, math.epsilon(f64));
    testing.expectWithinEpsilon(atom_record.z.?, 4.288, math.epsilon(f64));
    testing.expectWithinEpsilon(atom_record.occupancy.?, 1.00, math.epsilon(f64));
    testing.expectWithinEpsilon(atom_record.factor.?, 10.65, math.epsilon(f64));
    testing.expectEqualStrings(atom_record.element.?, "N");
    testing.expect(atom_record.charge == null);
}

test "Test print atom record to buffer" {
    const atom_record: AtomRecord = .{
        .atom_id = 542,
        .atom_name = "OH",
        .alt_loc = "a",
        .mol_name = "PRO",
        .chain_id = "G",
        .i_code = "p",
        .x = -1.0,
        .y = 2.0,
        .z = -3.15,
        .occupancy = 3.0,
        .factor = 1.0,
        .element = "Ba",
        .charge = -1.0,
    };

    var buf = try testing.allocator.alloc(u8, 81);
    defer testing.allocator.free(buf);
    const line = try atom_record.bufPrintAtomRecord(buf);
    const record = "ATOM    542  OH aPRO G    p     -1.000   2.000  -3.150  3.00  1.00          Ba-1\n";
    testing.expectEqualStrings(line, record);
}
