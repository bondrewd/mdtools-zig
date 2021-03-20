const std = @import("std");
const V = @import("vec.zig").V;

pub fn M(comptime T: type, comptime m: usize, comptime n: usize) type {
    if (@typeInfo(T) != .Float) @compileError("Expected float, found '" ++ @typeName(T) ++ "'");

    return struct {
        data: [m][n]T = undefined,

        const Self = @This();
        pub const DataT = T;
        pub const len = [_]usize{ m, n };

        pub fn new() Self {
            return .{};
        }

        pub fn zeros() Self {
            return Self{
                .data = [_][n]T{[_]T{0} ** n} ** m,
            };
        }

        pub fn ones() Self {
            return Self{
                .data = [_][n]T{[_]T{1} ** n} ** m,
            };
        }

        pub fn initFromArray(array: [m][n]T) Self {
            return Self{
                .data = array,
            };
        }

        pub fn add(self: Self, rhs: Self) Self {
            var rslt = new();
            for (self.data) |mat_row, i| {
                for (mat_row) |cell, j| {
                    rslt.data[i][j] = cell + rhs.data[i][j];
                }
            }
            return rslt;
        }

        pub fn mul(self: Self, rhs: Self) Self {
            var rslt = new();
            for (self.data) |mat_row, i| {
                for (mat_row) |cell, j| {
                    rslt.data[i][j] = cell * rhs.data[i][j];
                }
            }
            return rslt;
        }

        pub fn scale(self: Self, rhs: T) Self {
            var rslt = new();
            for (self.data) |mat_row, i| {
                for (mat_row) |cell, j| {
                    rslt.data[i][j] = cell * rhs;
                }
            }
            return rslt;
        }

        pub fn transpose(self: Self) M(T, n, m) {
            var rslt = M(T, n, m).new();
            for (self.data) |mat_row, i| {
                for (mat_row) |cell, j| {
                    rslt.data[j][i] = cell;
                }
            }
            return rslt;
        }

        fn MatMul(Rhs: anytype) type {
            if (comptime Self.DataT != Rhs.DataT or Self.len[1] != Rhs.len[0]) {
                @compileError("Trying to multiply matrices with incompatible dimensions");
            }
            return M(T, Self.len[0], Rhs.len[1]);
        }

        pub fn matMul(self: Self, rhs: anytype) MatMul(@TypeOf(rhs)) {
            const Rhs = MatMul(@TypeOf(rhs));
            var rslt = Rhs.zeros();

            var i: usize = 0;
            var j: usize = 0;
            var k: usize = 0;

            while (i < Self.len[0]) : (i += 1) {
                k = 0;
                while (k < Self.len[1]) : (k += 1) {
                    j = 0;
                    while (j < Rhs.len[1]) : (j += 1) {
                        rslt.data[i][j] += self.data[i][k] * rhs.data[k][j];
                    }
                }
            }
            return rslt;
        }

        pub fn swizzlingRows(self: Self, index: [m]usize) Self {
            var rslt = new();
            for (index) |i, j| {
                rslt.data[j] = self.data[i];
            }
            return rslt;
        }

        pub fn swizzlingCols(self: Self, index: [n]usize) Self {
            var rslt = new();
            var k: usize = undefined;
            for (index) |i, j| {
                k = 0;
                while (k < m) : (k += 1) {
                    rslt.data[k][j] = self.data[k][i];
                }
            }
            return rslt;
        }

        const Order = enum { Row, Col };

        pub fn toVec(self: Self, order: Order) V(T, m * n) {
            var v = V(T, m * n).new();

            var i: usize = 0;
            var j: usize = 0;

            switch (order) {
                .Row => {
                    while (i < m) : (i += 1) {
                        j = 0;
                        while (j < n) : (j += 1) {
                            v.data[i * n + j] = self.data[i][j];
                        }
                    }
                },
                .Col => {
                    while (i < n) : (i += 1) {
                        j = 0;
                        while (j < m) : (j += 1) {
                            v.data[i * m + j] = self.data[j][i];
                        }
                    }
                },
            }

            return v;
        }
    };
}

const testing = std.testing;
test "M of f32" {
    // Usage
    var v = M(f32, 3, 2).initFromArray(.{
        .{ 0.0, 1.0 },
        .{ 2.0, 3.0 },
        .{ 4.0, 5.0 },
    });
    testing.expectEqual(v, M(f32, 3, 2).initFromArray(.{
        .{ 0.0, 1.0 },
        .{ 2.0, 3.0 },
        .{ 4.0, 5.0 },
    }));
}

test "M zeros" {
    // Usage
    var v = M(f32, 3, 2).zeros();
    testing.expectEqual(v, M(f32, 3, 2).initFromArray(.{
        .{ 0.0, 0.0 },
        .{ 0.0, 0.0 },
        .{ 0.0, 0.0 },
    }));
}

test "M ones" {
    // Usage
    var v = M(f32, 3, 2).ones();
    testing.expectEqual(v, M(f32, 3, 2).initFromArray(.{
        .{ 1.0, 1.0 },
        .{ 1.0, 1.0 },
        .{ 1.0, 1.0 },
    }));
}

test "M element-wise add" {
    var v = M(f64, 3, 3).initFromArray(.{
        .{ 1.0, 2.0, 3.0 },
        .{ 4.0, 5.0, 6.0 },
        .{ 7.0, 8.0, 9.0 },
    });
    var w = M(f64, 3, 3).initFromArray(.{
        .{ 2.0, 4.0, 6.0 },
        .{ 8.0, 10.0, 12.0 },
        .{ 14.0, 16.0, 18.0 },
    });

    // Usage
    var rslt = v.add(w);
    testing.expectEqual(rslt, M(f64, 3, 3).initFromArray(.{
        .{ 3.0, 6.0, 9.0 },
        .{ 12.0, 15.0, 18.0 },
        .{ 21.0, 24.0, 27.0 },
    }));

    // Properties
    testing.expectEqual(v.add(M(f64, 3, 3).zeros()), v);
}

test "M element-wise mul" {
    var v = M(f64, 3, 3).initFromArray(.{
        .{ 1.0, 2.0, 3.0 },
        .{ 4.0, 5.0, 6.0 },
        .{ 7.0, 8.0, 9.0 },
    });
    var w = M(f64, 3, 3).initFromArray(.{
        .{ 2.0, 4.0, 6.0 },
        .{ 8.0, 10.0, 12.0 },
        .{ 14.0, 16.0, 18.0 },
    });

    // Usage
    var rslt = v.mul(w);
    testing.expectEqual(rslt, M(f64, 3, 3).initFromArray(.{
        .{ 2.0, 8.0, 18.0 },
        .{ 32.0, 50.0, 72.0 },
        .{ 98.0, 128.0, 162.0 },
    }));

    // Properties
    testing.expectEqual(v.mul(M(f64, 3, 3).ones()), v);
    testing.expectEqual(v.mul(M(f64, 3, 3).zeros()), M(f64, 3, 3).zeros());
}

test "M scale" {
    var v = M(f64, 3, 3).initFromArray(.{
        .{ 1.0, 2.0, 3.0 },
        .{ 4.0, 5.0, 6.0 },
        .{ 7.0, 8.0, 9.0 },
    });

    // Usage
    var rslt = v.scale(10.0);
    testing.expectEqual(rslt, M(f64, 3, 3).initFromArray(.{
        .{ 10.0, 20.0, 30.0 },
        .{ 40.0, 50.0, 60.0 },
        .{ 70.0, 80.0, 90.0 },
    }));

    // Properties
    testing.expectEqual(v.scale(1.0), v);
    testing.expectEqual(v.scale(0.0), M(f64, 3, 3).zeros());
}

test "M matMul same dimension" {
    var v = M(f64, 3, 3).initFromArray(.{
        .{ 1.0, 2.0, 3.0 },
        .{ 4.0, 5.0, 6.0 },
        .{ 7.0, 8.0, 9.0 },
    });
    var w = M(f64, 3, 3).initFromArray(.{
        .{ 2.0, 4.0, 6.0 },
        .{ 8.0, 3.0, 2.0 },
        .{ 1.0, 6.0, 8.0 },
    });

    // Usage
    var rslt = v.matMul(w);
    testing.expectEqual(rslt, M(f64, 3, 3).initFromArray(.{
        .{ 21.0, 28.0, 34.0 },
        .{ 54.0, 67.0, 82.0 },
        .{ 87.0, 106.0, 130.0 },
    }));

    // Properties
    testing.expectEqual(v.matMul(M(f64, 3, 3).zeros()), M(f64, 3, 3).zeros());
}

test "M matMul different dimension" {
    var m = M(f64, 2, 3).initFromArray(.{
        .{ 1.0, 2.0, 3.0 },
        .{ 4.0, 5.0, 6.0 },
    });
    var n = M(f64, 3, 4).initFromArray(.{
        .{ 1.0, 2.0, 3.0, 4.0 },
        .{ 5.0, 6.0, 7.0, 8.0 },
        .{ 9.0, 1.0, 2.0, 3.0 },
    });

    // Usage
    var rslt = m.matMul(n);
    testing.expectEqual(rslt, M(f64, 2, 4).initFromArray(.{
        .{ 38.0, 17.0, 23.0, 29.0 },
        .{ 83.0, 44.0, 59.0, 74.0 },
    }));
}

test "M transpose" {
    var a = M(f64, 2, 3).initFromArray(.{
        .{ 1.0, 2.0, 3.0 },
        .{ 4.0, 5.0, 6.0 },
    });

    // Usage
    var rslt = a.transpose();
    testing.expectEqual(rslt, M(f64, 3, 2).initFromArray(.{
        .{ 1.0, 4.0 },
        .{ 2.0, 5.0 },
        .{ 3.0, 6.0 },
    }));
}

test "M swizzling" {
    var a = M(f64, 3, 4).initFromArray(.{
        .{ 0.0, 1.0, 2.0, 3.0 },
        .{ 4.0, 5.0, 6.0, 7.0 },
        .{ 8.0, 9.0, 10.0, 11.0 },
    });

    // Usage
    var rslt = a.swizzlingRows(.{ 2, 0, 1 });
    testing.expectEqual(rslt, M(f64, 3, 4).initFromArray(.{
        .{ 8.0, 9.0, 10.0, 11.0 },
        .{ 0.0, 1.0, 2.0, 3.0 },
        .{ 4.0, 5.0, 6.0, 7.0 },
    }));

    rslt = a.swizzlingCols(.{ 2, 1, 3, 0 });
    testing.expectEqual(rslt, M(f64, 3, 4).initFromArray(.{
        .{ 2.0, 1.0, 3.0, 0.0 },
        .{ 6.0, 5.0, 7.0, 4.0 },
        .{ 10.0, 9.0, 11.0, 8.0 },
    }));
}

test "M to vector" {
    var a = M(f32, 2, 3).initFromArray(.{
        .{ 0.0, 1.0, 2.0 },
        .{ 3.0, 4.0, 5.0 },
    });

    testing.expectEqual(a.toVec(.Row), V(f32, 6).initFromArray(.{ 0, 1, 2, 3, 4, 5 }));
    testing.expectEqual(a.toVec(.Col), V(f32, 6).initFromArray(.{ 0, 3, 1, 4, 2, 5 }));
}

pub fn identity(comptime T: type, comptime n: usize) comptime M(T, n, n) {
    var m = M(T, n, n).zeros();
    var i: usize = 0;
    while (i < n) : (i += 1) m.data[i][i] = 1;
    return m;
}

test "Identity matrix" {
    var i = identity(f32, 3);
    testing.expectEqual(i.data, .{
        .{ 1, 0, 0 },
        .{ 0, 1, 0 },
        .{ 0, 0, 1 },
    });
}
