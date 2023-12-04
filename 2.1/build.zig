const Build = @import("std").Build;
const LazyPath = @import("std").Build.LazyPath;
const Compile = @import("std").Build.Step.Compile;
const Run = @import("std").Build.Step.Run;
const OptimizeMode = @import("std").builtin.OptimizeMode;
const CrossTarget = @import("std").zig.CrossTarget;

const main_source_file: LazyPath = .{ .path = "main.zig" };

const modules = [_]struct { name: []const u8, source_file: LazyPath }{
    .{ .name = "io", .source_file = .{ .path = "../io.zig" } },
};

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "aoc",
        .root_source_file = .{ .path = "main.zig" },
        .target = target,
        .optimize = optimize,
    });
    addModules(b, exe);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn addModules(b: *Build, c: *Compile) void {
    for (modules) |module|
        c.addModule(module.name, b.createModule(.{ .source_file = module.source_file }));
}
