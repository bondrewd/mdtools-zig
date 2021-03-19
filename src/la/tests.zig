const std = @import("std");
const testing = std.testing;
const V = @import("vec.zig").V;
const M = @import("mat.zig").M;

// Unit tests
comptime {
    _ = @import("./vec.zig");
    _ = @import("./mat.zig");
}

// Integration tests
test "Matrix vector multiplication" {
    const m = M(f32, 3, 3).initFromArray(.{
        .{ 1, 0, 0 },
        .{ 0, 1, 0 },
        .{ 0, 0, 1 },
    });

    const v = V(f32, 3).initFromArray(.{ 0, 1, 2 });
    const a = v.asMat(.Row);
    const b = v.asMat(.Col);

    const scalar = a.matMul(m).matMul(b);
    testing.expectEqual(scalar, M(f32, 1, 1).initFromArray(.{.{5}}));
}
