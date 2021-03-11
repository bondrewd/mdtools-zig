const std = @import("std");
const testing = std.testing;

pub fn checkIsNumericArray(comptime T: type) void {
    switch (@typeInfo(T)) {
        .Array => |info| {
            const child = @typeInfo(info.child);
            if (child != .Int and child != .Float) {
                @compileError("Array child type is neither float nor int");
            }
        },
        else => @compileError("Type is not array of floats or array of ints"),
    }
}

pub fn checkIsFloat(comptime T: anytype) void {
    if (@typeInfo(T) != .Float) @compileError("Type is not float");
}

pub fn addArray(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    comptime const T = @TypeOf(a);
    comptime checkIsNumericArray(T);
    var rslt: T = undefined;
    for (a) |_, i| {
        rslt[i] = a[i] + b[i];
    }
    return rslt;
}

test "Add arrays" {
    const a = [_]i32{ 1, 2, 3 };
    const b = [_]i32{ 4, 5, 6 };

    const c = addArray(a, b);
    testing.expectEqual(c, .{ 5, 7, 9 });

    const x = [_]f64{ 5.0, 0.0, -4.0 };
    const y = [_]f64{ 1.0, 4.0, -2.0 };

    const z = addArray(x, y);
    testing.expectEqual(z, .{ 6.0, 4.0, -6.0 });

    const m = [_]u32{ 1, 2, 3 };
    const n = [_]u32{ 4, 7, 0 };

    const p = addArray(m, n);
    testing.expectEqual(p, .{ 5, 9, 3 });
}

pub fn subArray(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    comptime const T = @TypeOf(a);
    comptime checkIsNumericArray(T);
    var rslt: T = undefined;
    for (a) |_, i| {
        rslt[i] = a[i] - b[i];
    }
    return rslt;
}

test "Substract arrays" {
    const a = [_]i32{ 1, 2, 3 };
    const b = [_]i32{ 2, 8, 8 };

    const c = subArray(a, b);
    testing.expectEqual(c, .{ -1, -6, -5 });

    const x = [_]f64{ 5.0, 0.0, -4.0 };
    const y = [_]f64{ 1.0, 4.0, -2.0 };

    const z = subArray(x, y);
    testing.expectEqual(z, .{ 4.0, -4.0, -2.0 });

    const m = [_]u32{ 4, 9, 5 };
    const n = [_]u32{ 1, 5, 0 };

    const p = subArray(m, n);
    testing.expectEqual(p, .{ 3, 4, 5 });
}

pub fn mulArray(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    comptime const T = @TypeOf(a);
    comptime checkIsNumericArray(T);
    var rslt: T = undefined;
    for (a) |_, i| {
        rslt[i] = a[i] * b[i];
    }
    return rslt;
}

test "Multiply arrays" {
    const a = [_]i32{ 1, 2, 3 };
    const b = [_]i32{ 2, 8, 8 };

    const c = mulArray(a, b);
    testing.expectEqual(c, .{ 2, 16, 24 });

    const x = [_]f64{ 5.0, 0.0, -4.0 };
    const y = [_]f64{ 1.0, 4.0, -2.0 };

    const z = mulArray(x, y);
    testing.expectEqual(z, .{ 5.0, 0.0, 8.0 });

    const m = [_]u32{ 4, 9, 5 };
    const n = [_]u32{ 1, 5, 0 };

    const p = mulArray(m, n);
    testing.expectEqual(p, .{ 4, 45, 0 });
}

pub fn scaleArray(a: anytype, s: @typeInfo(@TypeOf(a)).Array.child) @TypeOf(a) {
    comptime const T = @TypeOf(a);
    comptime checkIsNumericArray(T);
    var rslt: T = undefined;
    for (a) |_, i| {
        rslt[i] = a[i] * s;
    }
    return rslt;
}

test "Scale arrays" {
    const a = [_]i32{ 1, 2, 3 };

    const b = scaleArray(a, -4);
    testing.expectEqual(b, .{ -4, -8, -12 });

    const x = [_]f64{ 5.0, 0.0, -4.0 };

    const y = scaleArray(x, 0.5);
    testing.expectEqual(y, .{ 2.5, 0., -2.0 });

    const m = [_]u32{ 4, 9, 5 };

    const n = scaleArray(m, 10);
    testing.expectEqual(n, .{ 40, 90, 50 });
}

pub fn addElementArray(a: anytype, e: @typeInfo(@TypeOf(a)).Array.child) @TypeOf(a) {
    comptime const T = @TypeOf(a);
    comptime checkIsNumericArray(T);
    var rslt: T = undefined;
    for (a) |_, i| {
        rslt[i] = a[i] + e;
    }
    return rslt;
}

test "Add element to arrays" {
    const a = [_]i32{ 1, 2, 3 };

    const b = addElementArray(a, -4);
    testing.expectEqual(b, .{ -3, -2, -1 });

    const x = [_]f64{ 5.0, 0.0, -4.0 };

    const y = addElementArray(x, 0.5);
    testing.expectEqual(y, .{ 5.5, 0.5, -3.5 });

    const m = [_]u32{ 4, 9, 5 };

    const n = addElementArray(m, 10);
    testing.expectEqual(n, .{ 14, 19, 15 });
}

pub fn meanArray(a: anytype) @typeInfo(@TypeOf(a)).Array.child {
    comptime const T = @TypeOf(a);
    comptime checkIsNumericArray(T);
    comptime const RetT = @typeInfo(T).Array.child;
    comptime checkIsFloat(RetT);
    var rslt: RetT = 0;
    for (a) |_, i| {
        rslt += a[i];
    }
    return rslt / @as(RetT, a.len);
}

test "Mean of arrays" {
    const a = [_]f32{ 1.0, 2.0, 3.0 };

    const b = meanArray(a);
    testing.expectEqual(b, 2.0);

    const x = [_]f64{ 5.0, 0.0, -4.0 };

    const y = meanArray(x);
    testing.expectEqual(y, 1.0 / 3.0);
}
