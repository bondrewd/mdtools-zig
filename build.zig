const std = @import("std");
const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) !void {
    // Get default release mode
    const mode = b.standardReleaseOptions();
    // Get default build target
    const target = b.standardTargetOptions(.{});

    // Create binary
    const exe = b.addExecutable("mdtools", "src/main.zig");
    // Add libraries
    exe.addPackagePath("argparse", "lib/argparse-zig/src/argparse.zig");
    // Configure binary
    exe.setTarget(target);
    exe.setBuildMode(mode);

    // Install binary
    exe.install();

    const exe_run = exe.run();
    exe_run.step.dependOn(b.getInstallStep());
    if (b.args) |args| exe_run.addArgs(args);

    // Create tests
    const tests = b.addTest("src/tests.zig");
    // Add libraries
    tests.addPackagePath("argparse", "lib/argparse-zig/src/argparse.zig");
    // Configure tests
    tests.setTarget(target);
    tests.setBuildMode(mode);

    const run_cmd = b.step("run", "Run the app");
    run_cmd.dependOn(&exe_run.step);

    const test_cmd = b.step("test", "Run all the tests");
    test_cmd.dependOn(&tests.step);
}
