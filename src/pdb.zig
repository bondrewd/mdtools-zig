const std = @import("std");
const fs = std.fs;
const io = std.io;
const os = std.os;
const fmt = std.fmt;
const mem = std.mem;

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

    pub fn closePdbFile() !void {
        self.file.close();
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
};

pub const AtomRecord = struct {
    atom_id: ?u32 = null,
    atom_name: ?[]const u8 = null,
    alt_loc: ?[]const u8 = null,
    mol_name: ?[]const u8 = null,
    chain_id: ?[]const u8 = null,
    mol_id: ?u32 = null,
    i_code: ?[]const u8 = null,
    x: ?f32 = null,
    y: ?f32 = null,
    z: ?f32 = null,
    occupancy: ?f32 = null,
    factor: ?f32 = null,
    element: ?[]const u8 = null,
    charge: ?f32 = null,

    const Self = @This();

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
            const x = fmt.parseFloat(f32, val) catch |_| null;

            val = mem.trim(u8, slice[38..46], " ");
            const y = fmt.parseFloat(f32, val) catch |_| null;

            val = mem.trim(u8, slice[46..54], " ");
            const z = fmt.parseFloat(f32, val) catch |_| null;

            val = mem.trim(u8, slice[54..60], " ");
            const occupancy = fmt.parseFloat(f32, val) catch |_| null;

            val = mem.trim(u8, slice[60..66], " ");
            const factor = fmt.parseFloat(f32, val) catch |_| null;

            val = mem.trim(u8, slice[76..78], " ");
            const element = if (val.len > 0) val else null;

            val = mem.trim(u8, slice[78..80], " ");
            const charge = fmt.parseFloat(f32, val) catch |_| null;

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
        if (buf.len < 80) return error.NoEnoughSpace;
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
