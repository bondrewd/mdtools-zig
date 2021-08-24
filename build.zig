const std = @import("std");
const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) !void {
    // Get default release mode
    const mode = b.standardReleaseOptions();
    // Get default build target
    const target = b.standardTargetOptions(.{});
    // Build options
    const ncurses = b.option(bool, "ncurses", "Build ncurses gui. Requires ncurses library installed") orelse false;
    const precision = b.option([]const u8, "precision", "mdtools working precision between f32 and f64 (Default: f32)") orelse "f32";

    // Create binary
    const exe = b.addExecutable("mdtools", "src/mdtools.zig");
    // Configure binary
    exe.setTarget(target);
    exe.setBuildMode(mode);

    // Link ncurses library
    if (ncurses) {
        exe.addBuildOption(bool, "enable_ncurses", ncurses);
        exe.linkSystemLibrary("ncurses");
        exe.linkLibC();
    }

    // Binary precision
    if (std.mem.eql(u8, precision, "f32")) {
        exe.addBuildOption(type, "working_precision", f32);
    } else if (std.mem.eql(u8, precision, "f64")) {
        exe.addBuildOption(type, "working_precision", f64);
    } else {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("Error: Expected precision 'f32' or 'f64', found '{s}'\n", .{precision});
        std.os.exit(0);
    }

    // Set output directory
    exe.setOutputDir("./bin");

    // Install binary
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_cmd = b.step("test", "Run all the tests");
    const tests = b.addTest("src/tests.zig");
    test_cmd.dependOn(&tests.step);
}
