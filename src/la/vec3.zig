const std = @import("std");
const mem = std.mem;
const math = std.math;
const testing = std.testing;

pub fn Vec3(comptime T: type) type {
    if (comptime @typeInfo(T) != .Float) @compileError("Vec3 only support float types");
    return struct {
        x: T = 0,
        y: T = 0,
        z: T = 0,
    };
}

pub fn checkIsVec3(comptime T: type) void {
    switch (@typeInfo(T)) {
        .Struct => |info| {
            const fields = info.fields;
            // Check number of fields
            if (fields.len != 3) @compileError("Type is not Vec3");
            // Check fields' names
            if (comptime !mem.eql(u8, fields[0].name, "x")) @compileError("First field is not named 'x'");
            if (comptime !mem.eql(u8, fields[1].name, "y")) @compileError("Second field is not named 'y'");
            if (comptime !mem.eql(u8, fields[2].name, "z")) @compileError("Third field is not named 'z'");
            // Check field type is float
            if (comptime @typeInfo(fields[0].field_type) != .Float) @compileError("Field types are not floats");
            // Check fiels are of the same type
            if (comptime fields[0].field_type != fields[1].field_type) @compileError("Vec3 fields are equal");
            if (comptime fields[0].field_type != fields[2].field_type) @compileError("Vec3 fields are equal");
            // Check default valuels
            if (fields[0].default_value) |x| {
                if (comptime x != 0) @compileError("Default value of x field is not 0");
            } else {
                @compileError("Default value of x field is not 0");
            }
            if (fields[1].default_value) |y| {
                if (comptime y != 0) @compileError("Default value of y field is not 0");
            } else {
                @compileError("Default value of y field is not 0");
            }
            if (fields[2].default_value) |z| {
                if (comptime z != 0) @compileError("Default value of z field is not 0");
            } else {
                @compileError("Default value of z field is not 0");
            }
        },
        else => @compileError("Type is not Vec3"),
    }
}

test "Test checkIsVec3" {
    comptime const Vec = Vec3(f32);
    checkIsVec3(Vec);
    checkIsVec3(struct { x: f32 = 0, y: f32 = 0, z: f32 = 0 });
}

pub fn add(v1: anytype, v2: @TypeOf(v1)) @TypeOf(v1) {
    comptime checkIsVec3(@TypeOf(v1));
    return .{
        .x = v1.x + v2.x,
        .y = v1.y + v2.y,
        .z = v1.z + v2.z,
    };
}

test "Test vec3 add" {
    const Vec = Vec3(f32);
    const v1: Vec = .{ .x = 0.0, .y = 1.0, .z = 2.0 };
    const v2: Vec = .{ .x = 3.0, .y = 4.0, .z = 5.0 };
    testing.expectEqual(add(v1, v2), .{ .x = 3.0, .y = 5.0, .z = 7.0 });

    // Check properties
    const zero: Vec = .{ .x = 0, .y = 0, .z = 0 };
    testing.expectEqual(add(v1, zero), v1);
    testing.expectEqual(add(v2, zero), v2);

    testing.expectEqual(add(v1, v2), add(v2, v1));
}

pub fn scale(v: anytype, s: @TypeOf(v.x)) @TypeOf(v) {
    checkIsVec3(@TypeOf(v));
    return .{
        .x = v.x * s,
        .y = v.y * s,
        .z = v.z * s,
    };
}

test "Test vec3 scale" {
    const Vec = Vec3(f32);
    const v: Vec = .{ .x = 0.0, .y = 1.0, .z = 2.0 };
    testing.expectEqual(scale(v, 4.0), .{ .x = 0.0, .y = 4.0, .z = 8.0 });
    const s: f32 = -3.0;
    testing.expectEqual(scale(v, s), .{ .x = 0.0, .y = -3.0, .z = -6.0 });

    // Check properties
    testing.expectEqual(scale(v, 1), v);
    testing.expectEqual(scale(v, 0), .{ .x = 0, .y = 0, .z = 0 });
}

pub fn dot(v1: anytype, v2: @TypeOf(v1)) @TypeOf(v1.x) {
    checkIsVec3(@TypeOf(v1));
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
}

test "Test vec3 dot product" {
    const Vec = Vec3(f32);
    const v1: Vec = .{ .x = 0.0, .y = 1.0, .z = 2.0 };
    const v2: Vec = .{ .x = 3.0, .y = 4.0, .z = 5.0 };
    testing.expectEqual(dot(v1, v2), 14.0);

    // Check properties
    const i: Vec = .{ .x = 1.0, .y = 0.0, .z = 0.0 };
    const j: Vec = .{ .x = 0.0, .y = 1.0, .z = 0.0 };
    const k: Vec = .{ .x = 0.0, .y = 0.0, .z = 1.0 };

    testing.expectEqual(dot(i, j), 0);
    testing.expectEqual(dot(j, k), 0);
    testing.expectEqual(dot(k, i), 0);

    testing.expectEqual(dot(i, i), 1);
    testing.expectEqual(dot(j, j), 1);
    testing.expectEqual(dot(k, k), 1);

    testing.expectEqual(dot(i, j), dot(j, i));
    testing.expectEqual(dot(j, k), dot(k, j));
    testing.expectEqual(dot(k, i), dot(i, k));
}

pub fn norm(v: anytype) @TypeOf(v.x) {
    checkIsVec3(@TypeOf(v));
    return math.sqrt(dot(v, v));
}

test "Test vec3 norm" {
    const Vec = Vec3(f32);
    const v: Vec = .{ .x = 1.0, .y = 2.0, .z = 3.0 };
    testing.expectEqual(norm(v), math.sqrt(14.0));

    // Check properties
    testing.expectEqual(norm(v), math.sqrt(dot(v, v)));
}

pub fn normalize(v: anytype) @TypeOf(v) {
    checkIsVec3(@TypeOf(v));
    const n = norm(v);
    return .{
        .x = v.x / n,
        .y = v.y / n,
        .z = v.z / n,
    };
}

test "Test vec3 normalize" {
    const Vec = Vec3(f32);
    const v: Vec = .{ .x = 1.0, .y = 2.0, .z = 3.0 };

    const n = norm(v);
    testing.expectEqual(normalize(v), .{ .x = 1 / n, .y = 2 / n, .z = 3 / n });

    // Check properties
    testing.expectWithinEpsilon(dot(normalize(v), normalize(v)), 1.0, math.epsilon(f32));
}

pub fn cross(v1: anytype, v2: @TypeOf(v1)) @TypeOf(v1) {
    checkIsVec3(@TypeOf(v1));
    return .{
        .x = v1.y * v2.z - v1.z * v2.y,
        .y = v1.z * v2.x - v1.x * v2.z,
        .z = v1.x * v2.y - v1.y * v2.x,
    };
}

test "Test vec3 cross" {
    const Vec = Vec3(f32);
    const v1: Vec = .{ .x = 0.0, .y = 1.0, .z = 2.0 };
    const v2: Vec = .{ .x = 3.0, .y = 4.0, .z = 5.0 };
    testing.expectEqual(cross(v1, v2), .{ .x = -3.0, .y = 6.0, .z = -3.0 });

    // Check properties
    const i: Vec = .{ .x = 1.0, .y = 0.0, .z = 0.0 };
    const j: Vec = .{ .x = 0.0, .y = 1.0, .z = 0.0 };
    const k: Vec = .{ .x = 0.0, .y = 0.0, .z = 1.0 };

    testing.expectEqual(cross(i, j), k);
    testing.expectEqual(cross(j, k), i);
    testing.expectEqual(cross(k, i), j);

    testing.expectEqual(cross(i, i), .{ .x = 0.0, .y = 0.0, .z = 0.0 });
    testing.expectEqual(cross(j, j), .{ .x = 0.0, .y = 0.0, .z = 0.0 });
    testing.expectEqual(cross(k, k), .{ .x = 0.0, .y = 0.0, .z = 0.0 });

    testing.expectEqual(cross(i, j), scale(cross(j, i), -1));
    testing.expectEqual(cross(j, k), scale(cross(k, j), -1));
    testing.expectEqual(cross(k, i), scale(cross(i, k), -1));
}

pub fn rotationMatrix(a: anytype, b: @TypeOf(a)) [3]@TypeOf(a) {
    checkIsVec3(@TypeOf(a));
    const T = @TypeOf(a.x);
    // Normalize vectors
    const an = normalize(a);
    const bn = normalize(b);
    // cosine
    const c = dot(an, bn);

    const v = cross(an, bn);

    const id: [3][3]T = .{
        .{ 1, 0, 0 },
        .{ 0, 1, 0 },
        .{ 0, 0, 1 },
    };

    const m: [3][3]T = .{
        .{ 0.0, -v.z, v.y },
        .{ v.z, 0.0, -v.x },
        .{ -v.y, v.x, 0.0 },
    };

    const n: [3][3]T = .{
        .{ -(v.y * v.y + v.z * v.z), v.x * v.y, v.x * v.z },
        .{ v.y * v.x, -(v.x * v.x + v.z * v.z), v.y * v.z },
        .{ v.z * v.x, v.z * v.y, -(v.x * v.x + v.y * v.y) },
    };

    var rot: [3][3]T = undefined;
    var i: usize = 0;
    while (i < 3) : (i += 1) {
        var j: usize = 0;
        while (j < 3) : (j += 1) {
            rot[i][j] = id[i][j] + m[i][j] + n[i][j] / (1.0 + c);
        }
    }

    return .{
        .{ .x = rot[0][0], .y = rot[0][1], .z = rot[0][2] },
        .{ .x = rot[1][0], .y = rot[1][1], .z = rot[1][2] },
        .{ .x = rot[2][0], .y = rot[2][1], .z = rot[2][2] },
    };
}

test "Test vec3 rotation matrix " {
    const Vec = Vec3(f32);
    const v1: Vec = .{ .x = 1.0, .y = 0.0, .z = 0.0 };
    const v2: Vec = .{ .x = 0.0, .y = 1.0, .z = 0.0 };
    const rot = rotationMatrix(v1, v2);
    testing.expectEqual(rot, .{
        .{ .x = 0, .y = -1, .z = 0 },
        .{ .x = 1, .y = 0, .z = 0 },
        .{ .x = 0, .y = 0, .z = 1 },
    });
}

pub fn rotate(v: anytype, rotation: [3]@TypeOf(v)) @TypeOf(v) {
    checkIsVec3(@TypeOf(v));
    return .{
        .x = dot(rotation[0], v),
        .y = dot(rotation[1], v),
        .z = dot(rotation[2], v),
    };
}

test "Test vec3 rotate" {
    const Vec = Vec3(f64);
    var v1: Vec = .{ .x = 1.0, .y = 0.0, .z = 0.0 };
    var v2: Vec = .{ .x = 0.0, .y = 1.0, .z = 0.0 };
    var v3 = rotate(v1, rotationMatrix(v1, v2));
    testing.expectEqual(v3, v2);

    v1 = .{ .x = 1.0, .y = 0.0, .z = 0.0 };
    v2 = .{ .x = 0.0, .y = -1.0, .z = 0.0 };
    v3 = rotate(v1, rotationMatrix(v1, v2));
    testing.expectEqual(v3, v2);

    v1 = .{ .x = 10.0, .y = 0.0, .z = 0.0 };
    v2 = .{ .x = 3.0, .y = 4.0, .z = 0.0 };
    v3 = rotate(v1, rotationMatrix(v1, v2));
    testing.expectWithinMargin(v3.x, 6, 1e-8);
    testing.expectWithinMargin(v3.y, 8, 1e-8);
    testing.expectWithinMargin(v3.z, 0, 1e-8);
}
