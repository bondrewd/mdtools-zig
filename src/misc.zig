const std = @import("std");

pub fn swap(comptime T: type, x: *T, y: *T) void {
    const tmp = x.*;
    x.* = y.*;
    y.* = tmp;
}

pub const Ordering = enum {
    Ascending,
    Descending,
};

pub fn orderTriplet(comptime T: type, x: *T, y: *T, z: *T, ord: Ordering) void {
    switch (@typeInfo(T)) {
        .Int, Float => {},
        else => @compileError("Expected int or float, found '" ++ @typeName(T) ++ "'"),
    }

    switch (ord) {
        .Ascending => {
            if (x.* > y.*) swap(T, x, y);
            if (x.* > z.*) swap(T, x, z);
            if (y.* > z.*) swap(T, y, z);
        },
        .Descending => {
            if (x.* < y.*) swap(T, x, y);
            if (x.* < z.*) swap(T, x, z);
            if (y.* < z.*) swap(T, y, z);
        },
    }
}
