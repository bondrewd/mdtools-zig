const std = @import("std");
const pi = std.math.pi;
const pow = std.math.pow;
const cos = std.math.cos;
const sqrt = std.math.sqrt;
const acos = std.math.acos;
const testing = std.testing;
const epsilon = std.math.epsilon;
const solver = @import("./solver.zig");

pub fn eigenValuesSymmetricMatrix3x3(comptime T: type, a: [3][3]T) [3]T {
    // Check if diagonal
    const p1 = pow(T, a[0][1], 2) + pow(T, a[0][2], 2) + pow(T, a[1][2], 2);
    if (p1 == 0) {
        return .{ a[0][0], a[1][1], a[2][2] };
    } else {
        const q = (a[0][0] + a[1][1] + a[2][2]) / 3.0;
        const p2 = pow(T, (a[0][0] - q), 2) + pow(T, (a[1][1] - q), 2) + pow(T, (a[2][2] - q), 2) + 2 * p1;
        const p = sqrt(p2 / 6.0);
        const id: [3][3]T = .{
            .{ 1.0, 0.0, 0.0 },
            .{ 0.0, 1.0, 0.0 },
            .{ 0.0, 0.0, 1.0 },
        };
        var b: [3][3]T = undefined;
        var i: usize = 0;
        while (i < 3) : (i += 1) {
            var j: usize = 0;
            while (j < 3) : (j += 1) {
                b[i][j] = (a[i][j] - q * id[i][j]) / p;
            }
        }
        const b1 = b[0][0] * b[1][1] * b[2][2];
        const b2 = b[0][1] * b[1][2] * b[2][0];
        const b3 = b[0][2] * b[1][0] * b[2][1];

        const b4 = b[0][2] * b[1][1] * b[2][0];
        const b5 = b[0][1] * b[1][0] * b[2][2];
        const b6 = b[0][0] * b[1][2] * b[2][1];

        const r = (b1 + b2 + b3 - b4 - b5 - b6) / 2.0;
        const phi = if (r <= -1) pi / 3.0 else if (r >= 1) 0.0 else acos(r) / 3.0;

        const eig1 = q + 2 * p * cos(phi);
        const eig3 = q + 2 * p * cos(phi + (2 * pi / 3.0));
        const eig2 = 3 * q - eig1 - eig3;

        return .{ eig1, eig2, eig3 };
    }
}

test "Eigenvalues from a 3x3 symmetric matrix" {
    const a: [3][3]f32 = .{
        .{ 3, 2, 4 },
        .{ 2, 0, 2 },
        .{ 4, 2, 3 },
    };

    const a_eigen = eigenValuesSymmetricMatrix3x3(f32, a);
    testing.expectWithinEpsilon(a_eigen[0], 8, 1e-5);
    testing.expectWithinEpsilon(a_eigen[1], -1, 1e-5);
    testing.expectWithinEpsilon(a_eigen[2], -1, 1e-5);

    const b: [3][3]f32 = .{
        .{ 1, 2, 3 },
        .{ 2, 0, 4 },
        .{ 3, 4, 2 },
    };

    const b_eigen = eigenValuesSymmetricMatrix3x3(f32, b);
    testing.expectWithinEpsilon(b_eigen[0], 7.20786, 1e-5);
    testing.expectWithinEpsilon(b_eigen[1], -1.05663, 1e-5);
    testing.expectWithinEpsilon(b_eigen[2], -3.15123, 1e-5);
}

fn cross(comptime T: type, a: [3]T, b: [3]T) [3]T {
    return .{
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    };
}

fn dot(comptime T: type, a: [3]T, b: [3]T) T {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

fn scale(comptime T: type, a: [3]T, s: T) [3]T {
    return .{ a[0] / s, a[1] / s, a[2] / s };
}

pub fn eigenVectorsSymmetricMatrix3x3(comptime T: type, a: [3][3]T) [3][3]T {
    const eigen_vals = eigenValuesSymmetricMatrix3x3(T, a);
    var eigen_vecs: [3][3]T = undefined;

    var i: usize = 0;
    while (i < 3) : (i += 1) {
        const row0: [3]T = .{ a[0][0] - eigen_vals[i], a[0][1], a[0][2] };
        const row1: [3]T = .{ a[1][0], a[1][1] - eigen_vals[i], a[1][2] };
        const row2: [3]T = .{ a[2][0], a[2][1], a[2][2] - eigen_vals[i] };
        const r0xr1 = cross(T, row0, row1);
        const r0xr2 = cross(T, row0, row2);
        const r1xr2 = cross(T, row1, row2);
        const d0 = dot(T, r0xr1, r0xr1);
        const d1 = dot(T, r0xr2, r0xr2);
        const d2 = dot(T, r1xr2, r1xr2);
        var dmax = d0;
        var imax: u8 = 0;
        if (d1 > dmax) {
            dmax = d1;
            imax = 1;
        }
        if (d2 > dmax) imax = 2;
        switch (imax) {
            0 => eigen_vecs[i] = scale(T, r0xr1, 1.0 / sqrt(d0)),
            1 => eigen_vecs[i] = scale(T, r0xr2, 1.0 / sqrt(d1)),
            2 => eigen_vecs[i] = scale(T, r1xr2, 1.0 / sqrt(d2)),
            else => unreachable,
        }
    }

    return eigen_vecs;
}

test "Eigenvectors from a 3x3 symmetric matrix" {
    const a: [3][3]f32 = .{
        .{ -3, -2, -4 },
        .{ -2, 5, 2 },
        .{ -4, 2, 2 },
    };

    const a_va = eigenValuesSymmetricMatrix3x3(f32, a);
    const a_ve = eigenVectorsSymmetricMatrix3x3(f32, a);
    var i: usize = 0;
    while (i < 3) : (i += 1) {
        var m = a[0];
        m[0] -= a_va[i];
        var n = a[1];
        n[1] -= a_va[i];
        var p = a[2];
        p[2] -= a_va[i];
        var rslt: [3]f32 = .{ dot(f32, m, a_ve[i]), dot(f32, n, a_ve[i]), dot(f32, p, a_ve[i]) };
        testing.expectWithinMargin(rslt[0], 0.0, 1e-3);
        testing.expectWithinMargin(rslt[1], 0.0, 1e-3);
        testing.expectWithinMargin(rslt[2], 0.0, 1e-3);
    }

    const b: [3][3]f32 = .{
        .{ 1, 0, 0 },
        .{ 0, 2, 0 },
        .{ 0, 0, 3 },
    };

    const b_va = eigenValuesSymmetricMatrix3x3(f32, b);
    const b_ve = eigenVectorsSymmetricMatrix3x3(f32, b);
    i = 0;
    while (i < 3) : (i += 1) {
        var m = b[0];
        m[0] -= b_va[i];
        var n = b[1];
        n[1] -= b_va[i];
        var p = b[2];
        p[2] -= b_va[i];
        var rslt: [3]f32 = .{ dot(f32, m, b_ve[i]), dot(f32, n, b_ve[i]), dot(f32, p, b_ve[i]) };
        testing.expectWithinMargin(rslt[0], 0.0, 1e-6);
        testing.expectWithinMargin(rslt[1], 0.0, 1e-6);
        testing.expectWithinMargin(rslt[2], 0.0, 1e-6);
    }
}
