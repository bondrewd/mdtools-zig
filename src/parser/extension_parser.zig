const std = @import("std");

pub const FileFormat = enum {
    GRO,
    PDB,
    PSF,
    DCD,
    XTC,
    TRR,
};

pub const FileExtensionParser = struct {
    pub const ParserError = error{
        UnknownExtension,
    };

    pub fn parse(path: []const u8) !FileFormat {
        const ext = std.fs.path.extension(path);

        if (std.mem.eql(u8, ext, ".gro")) return .GRO;
        if (std.mem.eql(u8, ext, ".pdb")) return .PDB;
        if (std.mem.eql(u8, ext, ".dcd")) return .DCD;
        if (std.mem.eql(u8, ext, ".xtc")) return .XTC;
        if (std.mem.eql(u8, ext, ".trr")) return .TRR;
        if (std.mem.eql(u8, ext, ".psf")) return .PSF;

        return error.UnknownFileExtension;
    }
};
