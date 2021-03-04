const std = @import("std");
const fs = std.fs;
const io = std.io;
const os = std.os;
const fmt = std.fmt;
const mem = std.mem;
const argparse = @import("./argparse.zig");

const AtomRecord = struct {
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
};

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    var args = try argparse.parse(allocator);

    const input = fs.cwd().openFile(args.input.?, .{ .read = true }) catch |err| switch (err) {
        error.FileNotFound => {
            const stdout = io.getStdOut();
            var buf = try allocator.alloc(u8, 1024);
            const line = try fmt.bufPrint(buf, "Error: File '{s}' does not exits\n", .{args.input.?});
            _ = try stdout.write(line);
            os.exit(0);
        },
        else => return err,
    };
    defer input.close();

    var atom_records = std.ArrayList(AtomRecord).init(allocator);
    defer atom_records.deinit();

    while (true) {
        const line = try input.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', 256);
        if (line) |record| {
            if (record.len == 0) continue;
            if (record.len > 4 and mem.eql(u8, record[0..4], "ATOM")) {
                var val = mem.trim(u8, record[6..11], " ");
                const atom_id = fmt.parseUnsigned(u32, val, 10) catch |_| null;

                val = mem.trim(u8, record[12..16], " ");
                const atom_name = if (val.len > 0) val else null;

                val = mem.trim(u8, record[16..17], " ");
                const alt_loc = if (val.len > 0) val else null;

                val = mem.trim(u8, record[17..20], " ");
                const mol_name = if (val.len > 0) val else null;

                val = mem.trim(u8, record[21..22], " ");
                const chain_id = if (val.len > 0) val else null;

                val = mem.trim(u8, record[22..26], " ");
                const mol_id = fmt.parseUnsigned(u32, val, 10) catch |_| null;

                val = mem.trim(u8, record[26..27], " ");
                const i_code = if (val.len > 0) val else null;

                val = mem.trim(u8, record[30..38], " ");
                const x = fmt.parseFloat(f32, val) catch |_| null;

                val = mem.trim(u8, record[38..46], " ");
                const y = fmt.parseFloat(f32, val) catch |_| null;

                val = mem.trim(u8, record[46..54], " ");
                const z = fmt.parseFloat(f32, val) catch |_| null;

                val = mem.trim(u8, record[54..60], " ");
                const occupancy = fmt.parseFloat(f32, val) catch |_| null;

                val = mem.trim(u8, record[60..66], " ");
                const factor = fmt.parseFloat(f32, val) catch |_| null;

                val = mem.trim(u8, record[76..78], " ");
                const element = if (val.len > 0) val else null;

                val = mem.trim(u8, record[78..80], " ");
                const charge = fmt.parseFloat(f32, val) catch |_| null;

                try atom_records.append(.{
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
                });
            }
        } else {
            break;
        }
    }

    const output = try fs.cwd().createFile("./out.pdb", .{});

    var buf = try allocator.alloc(u8, 256);
    defer allocator.free(buf);
    for (atom_records.items) |atom_record| {
        var line: []u8 = undefined;
        if (atom_record.atom_id) |atom_id| {
            line = try fmt.bufPrint(buf, "ATOM  {d:>5}", .{atom_id});
        } else {
            line = try fmt.bufPrint(buf, "ATOM       ", .{});
        }

        if (atom_record.atom_name) |atom_name| {
            line = try fmt.bufPrint(buf, "{s: <12}{s: ^4}", .{ line, atom_name });
        } else {
            line = try fmt.bufPrint(buf, "{s: <12}    ", .{line});
        }

        if (atom_record.alt_loc) |alt_loc| {
            line = try fmt.bufPrint(buf, "{s: <16}{s:1}", .{ line, alt_loc });
        } else {
            line = try fmt.bufPrint(buf, "{s: <16} ", .{line});
        }

        if (atom_record.mol_name) |mol_name| {
            line = try fmt.bufPrint(buf, "{s: <17}{s: >3}", .{ line, mol_name });
        } else {
            line = try fmt.bufPrint(buf, "{s: <17}   ", .{line});
        }

        if (atom_record.chain_id) |chain_id| {
            line = try fmt.bufPrint(buf, "{s: <21}{s:1}", .{ line, chain_id });
        } else {
            line = try fmt.bufPrint(buf, "{s: <21} ", .{line});
        }

        if (atom_record.mol_id) |mol_id| {
            line = try fmt.bufPrint(buf, "{s: <22}{d: >4}", .{ line, mol_id });
        } else {
            line = try fmt.bufPrint(buf, "{s: <22}    ", .{line});
        }

        if (atom_record.i_code) |i_code| {
            line = try fmt.bufPrint(buf, "{s: <26}{s:1}", .{ line, i_code });
        } else {
            line = try fmt.bufPrint(buf, "{s: <26} ", .{line});
        }

        if (atom_record.x) |x| {
            line = try fmt.bufPrint(buf, "{s: <30}{d: >8.3}", .{ line, x });
        } else {
            line = try fmt.bufPrint(buf, "{s: <30}        ", .{line});
        }

        if (atom_record.y) |y| {
            line = try fmt.bufPrint(buf, "{s: <38}{d: >8.3}", .{ line, y });
        } else {
            line = try fmt.bufPrint(buf, "{s: <38}        ", .{line});
        }

        if (atom_record.z) |z| {
            line = try fmt.bufPrint(buf, "{s: <46}{d: >8.3}", .{ line, z });
        } else {
            line = try fmt.bufPrint(buf, "{s: <46}        ", .{line});
        }

        if (atom_record.occupancy) |occupancy| {
            line = try fmt.bufPrint(buf, "{s: <54}{d: >6.2}", .{ line, occupancy });
        } else {
            line = try fmt.bufPrint(buf, "{s: <54}      ", .{line});
        }

        if (atom_record.factor) |factor| {
            line = try fmt.bufPrint(buf, "{s: <60}{d: >6.2}", .{ line, factor });
        } else {
            line = try fmt.bufPrint(buf, "{s: <60}      ", .{line});
        }

        if (atom_record.element) |element| {
            line = try fmt.bufPrint(buf, "{s: <76}{s: >2}", .{ line, element });
        } else {
            line = try fmt.bufPrint(buf, "{s: <76}  ", .{line});
        }

        if (atom_record.charge) |charge| {
            line = try fmt.bufPrint(buf, "{s: <78}{d: >2.0}", .{ line, charge });
        } else {
            line = try fmt.bufPrint(buf, "{s: <78}  ", .{line});
        }

        line = try fmt.bufPrint(buf, "{s: <80}\n", .{line});

        _ = try output.write(line);
    }
}
