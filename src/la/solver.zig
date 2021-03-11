const std = @import("std");
const math = std.math;
const testing = std.testing;

fn checkIsSquareMatrix(comptime T: type) void {
    switch (@typeInfo(T)) {
        .Array => |info| {
            const n = info.len;
            switch (@typeInfo(info.child)) {
                .Array => |child_info| {
                    const m = child_info.len;
                    if (comptime @typeInfo(child_info.child) != .Float) {
                        @compileError("Square matrix child type is not float");
                    }
                    if (comptime n != m) {
                        @compileError("Matrix is not square");
                    }
                },
                else => @compileError("Type is not square matrix"),
            }
        },
        else => @compileError("Type is not square matrix"),
    }
}

fn ChildT(comptime T: type) type {
    switch (@typeInfo(T)) {
        .Array => |info| return info.child,
        else => @compileError("'a' is not of type array"),
    }
}

pub fn gaussSeidel(a: anytype, b: ChildT(@TypeOf(a)), max_iter: usize, eps: ChildT(ChildT(@TypeOf(a)))) ChildT(@TypeOf(a)) {
    checkIsSquareMatrix(@TypeOf(a));
    const T = ChildT(ChildT(@TypeOf(a)));

    const n = a.len;
    var x = [_]T{1.0} ** n;
    var x_old = [_]T{1.0} ** n;

    var iter: usize = 0;
    while (iter <= max_iter) : (iter += 1) {
        for (a[0..]) |row, i| {
            var s: T = 0.0;
            for (row[0..]) |v, j| {
                if (i == j) continue;
                s += a[i][j] * x[j];
            }
            x[i] = (b[i] - s) / a[i][i];
        }
        for (x[0..]) |_, i| {
            if (math.absFloat(x[i] - x_old[i]) > eps) break;
        }
        x_old = x;
    }
    return x;
}

test "Test Gauss-Seidel algorithm" {
    const a: [2][2]f32 = .{
        .{ 16.0, 3.0 },
        .{ 7.0, -11.0 },
    };

    const b: [2]f32 = .{ 11.0, 13.0 };

    const x = gaussSeidel(a, b, 100, math.epsilon(f32));
    testing.expectWithinEpsilon(x[0], 0.8122, 1e-4);
    testing.expectWithinEpsilon(x[1], -0.665, 1e-4);

    const m: [4][4]f64 = .{
        .{ 10.0, -1.0, 2.0, 0.0 },
        .{ -1.0, 11.0, -1.0, 3.0 },
        .{ 2.0, -1.0, 10.0, -1.0 },
        .{ 0.0, 3.0, -1.0, 8.0 },
    };

    const n: [4]f64 = .{ 6.0, 25.0, -11.0, 15.0 };

    const y = gaussSeidel(m, n, 100, math.epsilon(f64));
    testing.expectWithinEpsilon(y[0], 1.0, 1e-5);
    testing.expectWithinEpsilon(y[1], 2.0, 1e-5);
    testing.expectWithinEpsilon(y[2], -1.0, 1e-5);
    testing.expectWithinEpsilon(y[3], 1.0, 1e-5);
}
