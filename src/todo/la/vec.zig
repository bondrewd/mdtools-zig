const std = @import("std");
const math = std.math;
const M = @import("mat.zig").M;

pub fn V(comptime T: type, comptime n: usize) type {
    if (@typeInfo(T) != .Float) @compileError("Expected float, found '" ++ @typeName(T) ++ "'");

    return struct {
        data: [n]T = undefined,

        const Self = @This();
        pub const DataT = T;
        pub const len = n;

        pub fn new() Self {
            return .{};
        }

        pub fn zeros() Self {
            return .{
                .data = [_]T{0} ** n,
            };
        }

        pub fn ones() Self {
            return .{
                .data = [_]T{1} ** n,
            };
        }

        pub fn initFromArray(array: [n]T) Self {
            return Self{
                .data = array,
            };
        }

        pub fn add(self: Self, rhs: Self) Self {
            var rslt = new();
            for (self.data) |d, i| {
                rslt.data[i] = d + rhs.data[i];
            }
            return rslt;
        }

        pub fn mul(self: Self, rhs: Self) Self {
            var rslt = new();
            for (self.data) |d, i| {
                rslt.data[i] = d * rhs.data[i];
            }
            return rslt;
        }

        pub fn scale(self: Self, rhs: T) Self {
            var rslt = new();
            for (self.data) |d, i| {
                rslt.data[i] = d * rhs;
            }
            return rslt;
        }

        pub fn dot(self: Self, rhs: Self) T {
            var rslt: T = 0;
            for (self.data) |d, i| {
                rslt += d * rhs.data[i];
            }
            return rslt;
        }

        pub fn norm(self: Self) T {
            return math.sqrt(self.dot(self));
        }

        pub fn normN(self: Self, p: T) T {
            var acc: T = 0;
            for (self.data) |d| {
                acc += math.pow(f64, d, p);
            }
            return math.pow(f64, acc, 1.0 / p);
        }

        pub fn normalize(self: Self) Self {
            return self.scale(1 / self.norm());
        }

        pub fn swizzling(self: Self, index: [n]usize) Self {
            var rslt: Self = undefined;
            for (index) |i, j| {
                rslt.data[j] = self.data[i];
            }
            return rslt;
        }

        pub fn toMat(self: Self) M(T, n, 1) {
            var m = M(T, n, 1).new();
            for (self.data) |element, i| m.data[i][0] = element;
            return m;
        }
    };
}

const testing = std.testing;
test "Vec of f32" {
    // Usage
    var v = V(f32, 3).initFromArray(.{ 0.0, 1.0, 2.0 });
    testing.expectEqual(v.data, [3]f32{ 0.0, 1.0, 2.0 });
}

test "Vec zeros" {
    // Usage
    var v = V(f32, 3).zeros();
    testing.expectEqual(v.data, [3]f32{ 0.0, 0.0, 0.0 });
}

test "Vec ones" {
    // Usage
    var v = V(f32, 3).ones();
    testing.expectEqual(v.data, [3]f32{ 1.0, 1.0, 1.0 });
}

test "Vec element-wise add" {
    var v = V(f64, 3).initFromArray(.{ 1.0, 2.0, 3.0 });
    var w = V(f64, 3).initFromArray(.{ 2.0, 3.0, 4.0 });

    // Usage
    var rslt = v.add(w);
    testing.expectEqual(rslt.data, [3]f64{ 3.0, 5.0, 7.0 });

    // Properties
    testing.expectEqual(v.add(V(f64, 3).zeros()), v);
}

test "Vec element-wise mul" {
    var v = V(f64, 3).initFromArray(.{ 1.0, 2.0, 3.0 });
    var w = V(f64, 3).initFromArray(.{ 2.0, 3.0, 4.0 });

    // Usage
    var rslt = v.mul(w);
    testing.expectEqual(rslt.data, [3]f64{ 2.0, 6.0, 12.0 });

    // Properties
    testing.expectEqual(v.mul(V(f64, 3).ones()), v);
    testing.expectEqual(v.mul(V(f64, 3).zeros()), V(f64, 3).zeros());
}

test "Vec scale" {
    var v = V(f64, 3).initFromArray(.{ 1.0, 2.0, 3.0 });

    // Usage
    var rslt = v.scale(5.0);
    testing.expectEqual(rslt.data, [3]f64{ 5.0, 10.0, 15.0 });

    // Properties
    testing.expectEqual(v.scale(1.0), v);
    testing.expectEqual(v.scale(0.0), V(f64, 3).zeros());
}

test "Vec dot" {
    var v = V(f64, 3).initFromArray(.{ 1.0, 2.0, 3.0 });
    var w = V(f64, 3).initFromArray(.{ 2.0, 3.0, 4.0 });

    // Usage
    var rslt = v.dot(w);
    testing.expect(rslt == 20.0);

    // Properties
    testing.expect(v.dot(V(f64, 3).ones()) == 6.0);
    testing.expect(v.dot(V(f64, 3).zeros()) == 0.0);
}

test "Vec norm" {
    var v = V(f64, 2).initFromArray(.{ 3.0, 4.0 });

    // Usage
    var rslt = v.norm();
    testing.expect(v.norm() == 5.0);

    // Properties
    testing.expect(V(f64, 2).zeros().norm() == 0.0);
}

test "Vec normN" {
    var v = V(f64, 2).initFromArray(.{ 3.0, 4.0 });
    const epsilon = 0.000001;

    // Usage
    var rslt = v.normN(3);
    testing.expect(math.approxEq(f64, rslt, math.pow(f64, 91.0, 1.0 / 3.0), epsilon));
}

test "Vec normalize" {
    var v = V(f64, 2).initFromArray(.{ 3.0, 4.0 });
    const epsilon = 0.000001;

    // Usage
    var rslt = v.normalize();
    testing.expect(math.approxEq(f64, rslt.data[0], 0.6, epsilon));
    testing.expect(math.approxEq(f64, rslt.data[1], 0.8, epsilon));
    testing.expect(math.approxEq(f64, rslt.norm(), 1.0, epsilon));
}

test "Vec swizzling" {
    var v = V(f64, 4).initFromArray(.{ 0.0, 1.0, 2.0, 3.0 });

    // Usage
    var rslt = v.swizzling(.{ 2, 3, 0, 1 });
    testing.expectEqual(rslt.data, [4]f64{ 2.0, 3.0, 0.0, 1.0 });
}

test "Vec to matrix" {
    var v = V(f32, 3).initFromArray(.{ 0, 1, 2 });

    testing.expectEqual(v.toMat(), M(f32, 3, 1).initFromArray([3][1]f32{ .{0}, .{1}, .{2} }));
}
