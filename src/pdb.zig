const std = @import("std");
const fs = std.fs;
const io = std.io;
const os = std.os;
const fmt = std.fmt;
const mem = std.mem;
const math = std.math;
const testing = std.testing;
const misc = @import("./misc.zig");
const la = @import("./la.zig");
const vec = la.vec3;
const eigen = la.eigen;
const solver = la.solver;

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
        if (buf.len < 81) return error.NoEnoughSpace;
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

pub const PdbFile = struct {
    file: ?fs.File = null,
    allocator: *mem.Allocator,
    atom_records: std.ArrayList(AtomRecord),

    const Self = @This();

    pub fn init(allocator: *mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .atom_records = std.ArrayList(AtomRecord).init(allocator),
        };
    }

    pub fn initFromFile(dir: fs.Dir, sub_path: []const u8, allocator: *mem.Allocator) !Self {
        var file = PdbFile.init(allocator);
        try file.openPdbFile(dir, sub_path);
        try file.readAtomRecords();
        return file;
    }

    pub fn deinit(self: *Self) void {
        self.atom_records.deinit();
        if (self.file) |_| self.closePdbFile();
    }

    pub fn openPdbFile(self: *Self, dir: fs.Dir, sub_path: []const u8) !void {
        self.file = dir.openFile(sub_path, .{
            .read = true,
            .write = true,
        }) catch |err| switch (err) {
            error.FileNotFound => {
                var buf = try self.allocator.alloc(u8, 1024);
                const line = try fmt.bufPrint(buf, "Error: File '{s}' does not exits\n", .{sub_path});
                const stdout = io.getStdOut();
                _ = try stdout.write(line);
                os.exit(0);
            },
            else => return err,
        };
    }

    pub fn closePdbFile(self: Self) void {
        if (self.file) |file| file.close();
    }

    pub fn readAtomRecords(self: *Self) !void {
        if (self.file) |file| {
            try self.readAtomRecordsFromFile(file);
        } else {
            return error.FileFieldNotInitialized;
        }
    }

    pub fn readAtomRecordsFromFile(self: *Self, file: fs.File) !void {
        const reader = file.reader();
        while (true) {
            const line = try reader.readUntilDelimiterOrEofAlloc(self.allocator, '\n', 256);
            if (line) |record| {
                var atom_record = AtomRecord.parseAtomRecord(record) catch |_| continue;
                try self.atom_records.append(atom_record);
            } else {
                break;
            }
        }
    }

    pub fn writePdbToFile(self: Self, file: fs.File) !void {
        const writer = file.writer();
        var buf = try self.allocator.alloc(u8, 256);
        defer self.allocator.free(buf);

        for (self.atom_records.items) |atom_record| {
            const record = try atom_record.bufPrintAtomRecord(buf);
            _ = try writer.write(record);
        }
    }

    pub fn getCenterOfGeometry(self: Self) !vec.Vec3(f64) {
        var cog: vec.Vec3(f64) = .{};

        for (self.atom_records.items) |atom_record| {
            if (atom_record.hasMissingCoordinates()) return error.MissingCoordinateInformation;
            cog.x += atom_record.x.?;
            cog.y += atom_record.y.?;
            cog.z += atom_record.z.?;
        }

        const n = self.atom_records.items.len;
        cog = vec.scale(cog, 1 / @intToFloat(f64, n));

        return cog;
    }

    pub fn setCenterOfGeometry(self: *Self, new_cog: vec.Vec3(f64)) !void {
        const cog: vec.Vec3(f64) = try self.getCenterOfGeometry();
        const dr: vec.Vec3(f64) = .{
            .x = new_cog.x - cog.x,
            .y = new_cog.y - cog.y,
            .z = new_cog.z - cog.z,
        };

        for (self.atom_records.items) |*atom_record| {
            atom_record.*.x.? += dr.x;
            atom_record.*.y.? += dr.y;
            atom_record.*.z.? += dr.z;
        }
    }

    pub fn getCenterOfMass(self: Self) !vec.Vec3(f64) {
        var com: vec.Vec3(f64) = .{};
        var total_mass: f64 = 0.0;

        for (self.atom_records.items) |atom_record| {
            if (atom_record.hasMissingCoordinates()) return error.MissingCoordinateInformation;
            const mass: f64 = if (atom_record.element) |element| blk: {
                if (mem.eql(u8, element, "C")) break :blk @as(f64, 12.0107);
                if (mem.eql(u8, element, "O")) break :blk @as(f64, 15.9990);
                if (mem.eql(u8, element, "N")) break :blk @as(f64, 14.0067);
                if (mem.eql(u8, element, "S")) break :blk @as(f64, 32.0650);
                return error.UnknownElement;
            } else return error.MissingMassInformation;

            com.x += atom_record.x.? * mass;
            com.y += atom_record.y.? * mass;
            com.z += atom_record.z.? * mass;

            total_mass += mass;
        }

        com = vec.scale(com, 1 / total_mass);

        return com;
    }

    pub fn setCenterOfMass(self: *Self, new_com: vec.Vec3(f64)) !void {
        const com: vec.Vec3(f64) = try self.getCenterOfMass();
        const dr: vec.Vec3(f64) = .{
            .x = new_com.x - com.x,
            .y = new_com.y - com.y,
            .z = new_com.z - com.z,
        };

        for (self.atom_records.items) |*atom_record| {
            atom_record.*.x.? += dr.x;
            atom_record.*.y.? += dr.y;
            atom_record.*.z.? += dr.z;
        }
    }

    pub fn getInertiaTensor(self: Self) ![3][3]f64 {
        var tensor: [3][3]f64 = .{.{0.0} ** 3} ** 3;

        for (self.atom_records.items) |atom_record| {
            if (atom_record.hasMissingCoordinates()) return error.MissingCoordinateInformation;

            const mass: f64 = if (atom_record.element) |element| blk: {
                if (mem.eql(u8, element, "C")) break :blk @as(f64, 12.0107);
                if (mem.eql(u8, element, "O")) break :blk @as(f64, 15.9990);
                if (mem.eql(u8, element, "N")) break :blk @as(f64, 14.0067);
                if (mem.eql(u8, element, "S")) break :blk @as(f64, 32.0650);
                return error.UnknownElement;
            } else return error.MissingMassInformation;

            const x = atom_record.x.?;
            const y = atom_record.y.?;
            const z = atom_record.z.?;

            tensor[0][0] += mass * (y * y + z * z);
            tensor[1][1] += mass * (x * x + z * z);
            tensor[2][2] += mass * (x * x + y * y);

            tensor[0][1] -= mass * x * y;
            tensor[1][0] -= mass * y * x;

            tensor[0][2] -= mass * x * z;
            tensor[2][0] -= mass * z * x;

            tensor[1][2] -= mass * y * z;
            tensor[2][1] -= mass * z * y;
        }

        return tensor;
    }

    pub fn getPrincipalAxes(self: Self) ![3]vec.Vec3(f64) {
        const tensor = try self.getInertiaTensor();
        const eigenvec = eigen.eigenVectorsSymmetricMatrix3x3(f64, tensor);

        var axes: [3]vec.Vec3(f64) = undefined;
        for (axes) |*axis, i| {
            axis.* = .{ .x = eigenvec[i][0], .y = eigenvec[i][1], .z = eigenvec[i][2] };
            axis.* = vec.normalize(axis.*);
        }

        return axes;
    }

    const Axis = enum { X, Y, Z };
    pub fn alignPrincipalAxes(self: *Self, align_to_z: Axis) !void {
        const axes = try self.getPrincipalAxes();
        var rot_z: [3]vec.Vec3(f64) = undefined;
        var rot_x: [3]vec.Vec3(f64) = undefined;
        switch (align_to_z) {
            .X => {
                rot_z = vec.rotationMatrix(axes[0], .{ .x = 0, .y = 0, .z = 1 });
                const axis1_rot = vec.rotate(axes[1], rot_z);
                const axis2_rot = vec.rotate(axes[2], rot_z);
                if (vec.cross(axis1_rot, axis2_rot).z > 0) {
                    rot_x = vec.rotationMatrix(axis1_rot, .{ .x = 1, .y = 0, .z = 0 });
                } else {
                    rot_x = vec.rotationMatrix(axis2_rot, .{ .x = 1, .y = 0, .z = 0 });
                }
            },
            .Y => {
                rot_z = vec.rotationMatrix(axes[1], .{ .x = 0, .y = 0, .z = 1 });
                const axis0_rot = vec.rotate(axes[0], rot_z);
                const axis2_rot = vec.rotate(axes[2], rot_z);
                if (vec.cross(axis0_rot, axis2_rot).z > 0) {
                    rot_x = vec.rotationMatrix(axis0_rot, .{ .x = 1, .y = 0, .z = 0 });
                } else {
                    rot_x = vec.rotationMatrix(axis2_rot, .{ .x = 1, .y = 0, .z = 0 });
                }
            },

            .Z => {
                rot_z = vec.rotationMatrix(axes[2], .{ .x = 0, .y = 0, .z = 1 });
                const axis0_rot = vec.rotate(axes[0], rot_z);
                const axis1_rot = vec.rotate(axes[1], rot_z);
                if (vec.cross(axis0_rot, axis1_rot).z > 0) {
                    rot_x = vec.rotationMatrix(axis0_rot, .{ .x = 1, .y = 0, .z = 0 });
                } else {
                    rot_x = vec.rotationMatrix(axis1_rot, .{ .x = 1, .y = 0, .z = 0 });
                }
            },
        }

        for (self.atom_records.items) |*atom_record| {
            const r: vec.Vec3(f64) = .{
                .x = atom_record.x.?,
                .y = atom_record.y.?,
                .z = atom_record.z.?,
            };

            const r_z = vec.rotate(r, rot_z);
            const r_x = vec.rotate(r_z, rot_x);

            atom_record.x = r_x.x;
            atom_record.y = r_x.y;
            atom_record.z = r_x.z;
        }
    }
};

test "Test getting the center of geometry" {
    var pdb = PdbFile.init(testing.allocator);
    defer pdb.deinit();

    try pdb.atom_records.append(.{ .x = 3.0, .y = 0.0, .z = 0.0 });
    try pdb.atom_records.append(.{ .x = 0.0, .y = 3.0, .z = 0.0 });
    try pdb.atom_records.append(.{ .x = 0.0, .y = 0.0, .z = 3.0 });

    var cog = try pdb.getCenterOfGeometry();
    testing.expectEqual(cog, .{ .x = 1.0, .y = 1.0, .z = 1.0 });

    _ = pdb.atom_records.pop();
    _ = pdb.atom_records.pop();
    _ = pdb.atom_records.pop();

    try pdb.atom_records.append(.{ .x = 1.0, .y = 0.0, .z = 0.0 });
    try pdb.atom_records.append(.{ .x = 0.0, .y = 1.0, .z = 0.0 });
    try pdb.atom_records.append(.{ .x = 0.0, .y = 0.0, .z = 1.0 });
    try pdb.atom_records.append(.{ .x = -1.0, .y = 0.0, .z = 0.0 });
    try pdb.atom_records.append(.{ .x = 0.0, .y = -1.0, .z = 0.0 });
    try pdb.atom_records.append(.{ .x = 0.0, .y = 0.0, .z = -1.0 });

    cog = try pdb.getCenterOfGeometry();
    testing.expectEqual(cog, .{ .x = 0.0, .y = 0.0, .z = 0.0 });
}

test "Test setting the center of geometry" {
    var pdb = PdbFile.init(testing.allocator);
    defer pdb.deinit();

    try pdb.atom_records.append(.{ .x = 3.0, .y = 0.0, .z = 0.0 });
    try pdb.atom_records.append(.{ .x = 0.0, .y = 3.0, .z = 0.0 });
    try pdb.atom_records.append(.{ .x = 0.0, .y = 0.0, .z = 3.0 });

    try pdb.setCenterOfGeometry(.{ .x = 0.0, .y = 0.0, .z = 0.0 });
    testing.expect(pdb.atom_records.items[0].x.? == 2.0);
    testing.expect(pdb.atom_records.items[0].y.? == -1.0);
    testing.expect(pdb.atom_records.items[0].z.? == -1.0);

    testing.expect(pdb.atom_records.items[1].x.? == -1.0);
    testing.expect(pdb.atom_records.items[1].y.? == 2.0);
    testing.expect(pdb.atom_records.items[1].z.? == -1.0);

    testing.expect(pdb.atom_records.items[2].x.? == -1.0);
    testing.expect(pdb.atom_records.items[2].y.? == -1.0);
    testing.expect(pdb.atom_records.items[2].z.? == 2.0);
}

test "Test getting the center of mass" {
    var pdb = PdbFile.init(testing.allocator);
    defer pdb.deinit();

    try pdb.atom_records.append(.{ .x = 3.0, .y = 0.0, .z = 0.0, .element = "C" });
    try pdb.atom_records.append(.{ .x = 0.0, .y = 3.0, .z = 0.0, .element = "O" });
    try pdb.atom_records.append(.{ .x = 0.0, .y = 0.0, .z = 3.0, .element = "N" });

    var com = try pdb.getCenterOfMass();
    const eps = math.epsilon(f64);
    const c_mass = 12.0107;
    const o_mass = 15.9990;
    const n_mass = 14.0067;
    const total_mass = c_mass + o_mass + n_mass;
    testing.expectWithinEpsilon(com.x, 3 * c_mass / total_mass, eps);
    testing.expectWithinEpsilon(com.y, 3 * o_mass / total_mass, eps);
    testing.expectWithinEpsilon(com.z, 3 * n_mass / total_mass, eps);
}

test "Test setting the center of mass" {
    var pdb = PdbFile.init(testing.allocator);
    defer pdb.deinit();

    try pdb.atom_records.append(.{ .x = 3.0, .y = 0.0, .z = 0.0, .element = "C" });
    try pdb.atom_records.append(.{ .x = 0.0, .y = 3.0, .z = 0.0, .element = "O" });
    try pdb.atom_records.append(.{ .x = 0.0, .y = 0.0, .z = 3.0, .element = "N" });

    try pdb.setCenterOfMass(.{ .x = 0.0, .y = 0.0, .z = 0.0 });
    const eps = math.epsilon(f64);
    const c_mass = 12.0107;
    const o_mass = 15.9990;
    const n_mass = 14.0067;
    const total_mass = c_mass + o_mass + n_mass;
    testing.expectWithinEpsilon(pdb.atom_records.items[0].x.?, 3.0 - 3 * c_mass / total_mass, eps);
    testing.expectWithinEpsilon(pdb.atom_records.items[0].y.?, 0.0 - 3 * o_mass / total_mass, eps);
    testing.expectWithinEpsilon(pdb.atom_records.items[0].z.?, 0.0 - 3 * n_mass / total_mass, eps);

    testing.expectWithinEpsilon(pdb.atom_records.items[1].x.?, 0.0 - 3 * c_mass / total_mass, eps);
    testing.expectWithinEpsilon(pdb.atom_records.items[1].y.?, 3.0 - 3 * o_mass / total_mass, eps);
    testing.expectWithinEpsilon(pdb.atom_records.items[1].z.?, 0.0 - 3 * n_mass / total_mass, eps);

    testing.expectWithinEpsilon(pdb.atom_records.items[2].x.?, 0.0 - 3 * c_mass / total_mass, eps);
    testing.expectWithinEpsilon(pdb.atom_records.items[2].y.?, 0.0 - 3 * o_mass / total_mass, eps);
    testing.expectWithinEpsilon(pdb.atom_records.items[2].z.?, 3.0 - 3 * n_mass / total_mass, eps);
}

test "Test getting the inertia tensor" {
    var pdb = PdbFile.init(testing.allocator);
    defer pdb.deinit();

    try pdb.atom_records.append(.{ .x = 3.0, .y = 2.0, .z = 1.0, .element = "C" });
    try pdb.atom_records.append(.{ .x = 1.0, .y = 3.0, .z = 2.0, .element = "O" });
    try pdb.atom_records.append(.{ .x = 2.0, .y = 1.0, .z = 3.0, .element = "N" });

    const tensor = try pdb.getInertiaTensor();
    const eps = math.epsilon(f64);
    const c_mass = 12.0107;
    const o_mass = 15.9990;
    const n_mass = 14.0067;
    const total_mass = c_mass + o_mass + n_mass;

    testing.expectWithinEpsilon(tensor[0][0], 5.0 * c_mass + 13.0 * o_mass + 10.0 * n_mass, eps);
    testing.expectWithinEpsilon(tensor[0][1], -(6.0 * c_mass + 3.0 * o_mass + 2.0 * n_mass), eps);
    testing.expectWithinEpsilon(tensor[0][2], -(3.0 * c_mass + 2.0 * o_mass + 6.0 * n_mass), eps);

    testing.expectWithinEpsilon(tensor[1][0], -(6.0 * c_mass + 3.0 * o_mass + 2.0 * n_mass), eps);
    testing.expectWithinEpsilon(tensor[1][1], 10.0 * c_mass + 5.0 * o_mass + 13.0 * n_mass, eps);
    testing.expectWithinEpsilon(tensor[1][2], -(2.0 * c_mass + 6.0 * o_mass + 3.0 * n_mass), eps);

    testing.expectWithinEpsilon(tensor[2][0], -(3.0 * c_mass + 2.0 * o_mass + 6.0 * n_mass), eps);
    testing.expectWithinEpsilon(tensor[2][1], -(2.0 * c_mass + 6.0 * o_mass + 3.0 * n_mass), eps);
    testing.expectWithinEpsilon(tensor[2][2], 13.0 * c_mass + 10.0 * o_mass + 5.0 * n_mass, eps);
}

test "Test getting principal axes" {
    var pdb = PdbFile.init(testing.allocator);
    defer pdb.deinit();

    try pdb.atom_records.append(.{ .x = 3.0, .y = 2.0, .z = 1.0, .element = "C" });
    try pdb.atom_records.append(.{ .x = 1.0, .y = 3.0, .z = 2.0, .element = "O" });
    try pdb.atom_records.append(.{ .x = 2.0, .y = 1.0, .z = 3.0, .element = "N" });

    try pdb.alignPrincipalAxes(.X);
    var axes = try pdb.getPrincipalAxes();
    testing.expectWithinMargin(axes[0].x, 0.0, 1e-8);
    testing.expectWithinMargin(axes[0].y, 0.0, 1e-8);
    testing.expectWithinMargin(axes[0].z, 1.0, 1e-8);

    testing.expectWithinMargin(axes[1].x, -1.0, 1e-8);
    testing.expectWithinMargin(axes[1].y, 0.0, 1e-8);
    testing.expectWithinMargin(axes[1].z, 0.0, 1e-8);

    testing.expectWithinMargin(axes[2].x, 0.0, 1e-8);
    testing.expectWithinMargin(axes[2].y, -1.0, 1e-8);
    testing.expectWithinMargin(axes[2].z, 0.0, 1e-8);

    try pdb.alignPrincipalAxes(.Y);
    axes = try pdb.getPrincipalAxes();
    testing.expectWithinMargin(axes[0].x, 0.0, 1e-8);
    testing.expectWithinMargin(axes[0].y, -1.0, 1e-8);
    testing.expectWithinMargin(axes[0].z, 0.0, 1e-8);

    testing.expectWithinMargin(axes[1].x, 0.0, 1e-8);
    testing.expectWithinMargin(axes[1].y, 0.0, 1e-8);
    testing.expectWithinMargin(axes[1].z, -1.0, 1e-8);

    testing.expectWithinMargin(axes[2].x, 1.0, 1e-8);
    testing.expectWithinMargin(axes[2].y, 0.0, 1e-8);
    testing.expectWithinMargin(axes[2].z, 0.0, 1e-8);

    try pdb.alignPrincipalAxes(.Z);
    axes = try pdb.getPrincipalAxes();
    testing.expectWithinMargin(axes[0].x, 1.0, 1e-8);
    testing.expectWithinMargin(axes[0].y, 0.0, 1e-8);
    testing.expectWithinMargin(axes[0].z, 0.0, 1e-8);

    testing.expectWithinMargin(axes[1].x, 0.0, 1e-8);
    testing.expectWithinMargin(axes[1].y, 1.0, 1e-8);
    testing.expectWithinMargin(axes[1].z, 0.0, 1e-8);

    testing.expectWithinMargin(axes[2].x, 0.0, 1e-8);
    testing.expectWithinMargin(axes[2].y, 0.0, 1e-8);
    testing.expectWithinMargin(axes[2].z, 1.0, 1e-8);
}
