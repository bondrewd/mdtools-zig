const std = @import("std");
const fmt = std.fmt;
const eql = std.mem.eql;
const File = std.fs.File;
const testing = std.testing;
const ArrayList = std.ArrayList;
const Endian = std.builtin.Endian;
const Allocator = std.mem.Allocator;
const FileFormat = @import("parser.zig").FileFormat;
const FileExtensionParser = @import("parser.zig").FileExtensionParser;

pub const Atom = struct {
    id: u32,
    position: [3]f32,
};

pub const Universe = struct {
    atoms: ArrayList(Atom),
    n_atoms: u32,
    allocator: *Allocator,
    box: [3][3]f32,
    trajectory: Trajectory,
    readers: ArrayList(Reader),
    writers: ArrayList(Writer),

    const Self = @This();

    pub const Trajectory = struct {
        time: f32 = 0,
        time_step: f32 = 0,
        time_zero: u32 = 0,
        time_save: u32 = 0,
        frame: u32 = 0,
        n_frames: u32 = 0,
    };

    pub const Reader = struct {
        file: File,
        format: FileFormat,
        reader: File.Reader,
        universe: *Universe,

        fn readNextFrameDCD(self: *Reader) !void {
            // Read frame box size
            var block_s = @bitCast(u32, try self.reader.readBytesNoEof(4));
            if (block_s != 48) return error.BlockSizeMissmatch;

            const box_x = @bitCast(f64, try self.reader.readBytesNoEof(8)); // x
            const box_g = @bitCast(f64, try self.reader.readBytesNoEof(8)); // gamma
            const box_y = @bitCast(f64, try self.reader.readBytesNoEof(8)); // y
            const box_b = @bitCast(f64, try self.reader.readBytesNoEof(8)); // beta
            const box_a = @bitCast(f64, try self.reader.readBytesNoEof(8)); // alpha
            const box_z = @bitCast(f64, try self.reader.readBytesNoEof(8)); // z

            self.universe.box[0] = .{ @floatCast(f32, box_x), 0, 0 };
            self.universe.box[1] = .{ 0, @floatCast(f32, box_y), 0 };
            self.universe.box[2] = .{ 0, 0, @floatCast(f32, box_z) };

            var block_e = @bitCast(u32, try self.reader.readBytesNoEof(4));
            if (block_e != block_s) return error.BlockSizeMissmatch;

            // Read frame positions
            var i: u32 = 0;
            while (i < 3) : (i += 1) {
                block_s = @bitCast(u32, try self.reader.readBytesNoEof(4));
                if (block_s != self.universe.n_atoms * 4) return error.UnknownNumberOfAtoms;

                for (self.universe.atoms.items) |*atom| atom.position[i] = @bitCast(f32, try self.reader.readBytesNoEof(4));

                block_e = @bitCast(u32, try self.reader.readBytesNoEof(4));
                if (block_e != block_s) return error.BlockSizeMissmatch;
            }
        }

        fn readNextFrameXTC(self: *Reader) !void {}

        fn readNextFrameTRR(self: *Reader) !void {}
    };

    pub const Writer = struct {
        file: File,
        format: FileFormat,
        writer: File.Writer,
        universe: *Universe,

        fn writeFrameDCD(self: *Writer) !void {
            // Write frame box size
            try self.writer.writeIntNative(u32, 48);

            // -- Write x
            try self.writer.writeIntNative(u64, @bitCast(u32, self.universe.box[0][0]));

            // -- Write gamma
            try self.writer.writeIntNative(u64, 0);

            // -- Write y
            try self.writer.writeIntNative(u64, @bitCast(u32, self.universe.box[1][1]));

            // -- Write beta
            try self.writer.writeIntNative(u64, 0);

            // -- Write alpha
            try self.writer.writeIntNative(u64, 0);

            // -- Write z
            try self.writer.writeIntNative(u64, @bitCast(u32, self.universe.box[2][2]));

            // -- Write matching block size
            try self.writer.writeIntNative(u32, 48);

            // Write frame positions
            var i: u32 = 0;
            while (i < 3) : (i += 1) {
                // -- Write block size
                try self.writer.writeIntNative(u32, 4 * self.universe.n_atoms);

                // -- Write coordinate
                for (self.universe.atoms.items) |*atom| try self.writer.writeIntNative(u32, @bitCast(u32, atom.position[i]));

                // -- Write matching block size
                try self.writer.writeIntNative(u32, 4 * self.universe.n_atoms);
            }
        }

        fn writeFrameXTC(self: *Writer) !void {}

        fn writeFrameTRR(self: *Writer) !void {}
    };

    pub fn init(allocator: *Allocator) Self {
        return .{
            .atoms = ArrayList(Atom).init(allocator),
            .n_atoms = 0,
            .allocator = allocator,
            .box = [_][3]f32{[_]f32{0} ** 3} ** 3,
            .trajectory = .{},
            .readers = ArrayList(Reader).init(allocator),
            .writers = ArrayList(Writer).init(allocator),
        };
    }

    pub fn deinit(self: Self) void {
        self.atoms.deinit();

        for (self.readers.items) |r| {
            r.file.close();
        }
        self.readers.deinit();

        for (self.writers.items) |w| {
            w.file.close();
        }
        self.writers.deinit();
    }

    pub fn addAtom(self: *Self, atom: Atom) !void {
        try self.atoms.append(atom);
    }

    pub fn loadFile(self: *Self, file_path: []const u8) !void {
        const format = try FileExtensionParser.parse(file_path);
        switch (format) {
            .DCD => try self.loadTrajectoryDCD(file_path),
            else => {},
        }
    }

    fn loadTrajectoryDCD(self: *Self, file_path: []const u8) !void {
        // Open file
        const dcd_file = try std.fs.cwd().openFile(file_path, .{});

        // Get reader
        const r = dcd_file.reader();

        // Read first block
        var block_s = @bitCast(u32, try r.readBytesNoEof(4));
        if (block_s != 84) return error.BadFormat;

        // -- Read label
        const label = try r.readBytesNoEof(4);
        if (!eql(u8, &label, "CORD")) return error.BadFormat;

        // -- Read number of frames
        const n_frames = @bitCast(u32, try r.readBytesNoEof(4));

        // -- Read initial time
        const time_zero = @bitCast(u32, try r.readBytesNoEof(4));

        // -- Read steps between saves
        const time_save = @bitCast(u32, try r.readBytesNoEof(4));

        // -- Skip next 24 bytes
        try r.skipBytes(24, .{});

        // -- Read time step
        const time_step = @bitCast(f32, try r.readBytesNoEof(4));

        // -- Skip next 40 bytes
        try r.skipBytes(40, .{});

        var block_e = @bitCast(u32, try r.readBytesNoEof(4));
        if (block_e != block_s) return error.BadFormat;

        // Read second block
        block_s = @bitCast(u32, try r.readBytesNoEof(4));

        // -- Skip all the bytes in this block
        try r.skipBytes(block_s, .{});

        block_e = @bitCast(u32, try r.readBytesNoEof(4));
        if (block_e != block_s) return error.BlockSizeMissmatch;

        // Read third block
        block_s = @bitCast(u32, try r.readBytesNoEof(4));
        if (block_s != 4) return error.UnknownNumberOfAtoms;

        // -- Read number of atoms
        const n_atoms = @bitCast(u32, try r.readBytesNoEof(4));

        block_e = @bitCast(u32, try r.readBytesNoEof(4));
        if (block_e != block_s) return error.BlockSizeMissmatch;

        // Save trajectory info
        self.trajectory.time = @intToFloat(f32, time_zero) * time_step;
        self.trajectory.time_step = time_step;
        self.trajectory.time_zero = time_zero;
        self.trajectory.time_save = time_save;
        self.trajectory.n_frames = n_frames;

        // Save reader
        try self.readers.append(.{
            .file = dcd_file,
            .format = .DCD,
            .reader = r,
            .universe = self,
        });

        // Add atoms
        if (self.n_atoms == 0) {
            var i: u32 = 0;
            while (i < n_atoms) : (i += 1) {
                try self.addAtom(.{ .id = i, .position = [_]f32{0} ** 3 });
            }
            self.n_atoms = n_atoms;
        }

        // Load first frame
        try self.readNextFrame();
    }

    fn loadTrajectoryXTC(self: *Self, file_path: []const u8) !void {}

    fn loadTrajectoryTRR(self: *Self, file_path: []const u8) !void {}

    pub fn readNextFrame(self: *Self) !void {
        if (self.trajectory.frame == self.trajectory.n_frames) return;

        for (self.readers.items) |*r| {
            switch (r.format) {
                .DCD => try r.readNextFrameDCD(),
                .XTC => try r.readNextFrameXTC(),
                .TRR => try r.readNextFrameTRR(),
                else => return,
            }
        }

        // Update frame counter
        self.trajectory.frame += 1;

        // Update current time
        if (self.trajectory.frame == 1) {
            const dt = self.trajectory.time_step;
            const time_zero = @intToFloat(f32, self.trajectory.time_zero);

            self.trajectory.time = time_zero * dt;
        } else {
            const dt = self.trajectory.time_step;
            const time_save = @intToFloat(f32, self.trajectory.time_save);

            self.trajectory.time += time_save * dt;
        }
    }

    pub fn addWriter(self: *Self, file_path: []const u8) !void {
        const format = try FileExtensionParser.parse(file_path);
        switch (format) {
            .DCD => try self.addFrameWriterDCD(file_path),
            else => {},
        }
    }

    fn addFrameWriterDCD(self: *Self, file_path: []const u8) !void {
        // Open file
        const dcd_file = try std.fs.cwd().createFile(file_path, .{});

        // Get reader
        const w = dcd_file.writer();

        // Write first block size
        try w.writeIntNative(u32, 84);

        // -- Write label
        try w.writeAll("CORD");

        // -- Write number of frames
        try w.writeIntNative(u32, self.trajectory.n_frames);

        // -- Write initial time
        try w.writeIntNative(u32, self.trajectory.time_zero);

        // -- Write steps between saves
        try w.writeIntNative(u32, self.trajectory.time_save);

        // -- Write 0 in the next 24 bytes
        try w.writeByteNTimes(0, 24);

        // -- Write time step
        try w.writeIntNative(u32, @bitCast(u32, self.trajectory.time_step));

        // -- Write 0 in the next 40 bytes
        try w.writeByteNTimes(0, 40);

        // -- Write matching block size
        try w.writeIntNative(u32, 84);

        // Write second block size
        try w.writeIntNative(u32, 0);

        // -- Write matching block size
        try w.writeIntNative(u32, 0);

        // Write third block
        try w.writeIntNative(u32, 4);

        // -- Write number of atoms
        try w.writeIntNative(u32, self.n_atoms);

        // -- Write matching block size
        try w.writeIntNative(u32, 4);

        // Save trajectory info
        try self.writers.append(.{
            .file = dcd_file,
            .format = .DCD,
            .writer = w,
            .universe = self,
        });
    }

    pub fn write(self: *Self) !void {
        for (self.writers.items) |*w| {
            switch (w.format) {
                .DCD => try w.writeFrameDCD(),
                .XTC => try w.writeFrameXTC(),
                .TRR => try w.writeFrameTRR(),
                else => return,
            }
        }
    }
};
