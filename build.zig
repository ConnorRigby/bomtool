const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = b.standardOptimizeOption(.{});

    const libsqlite3 = b.addStaticLibrary(.{
        .name = "sqlite",
        .root_source_file = null,
        .target = target,
        .optimize = optimize,
        .version = null,
    });
    const libsqlilte_cflags = [_][]const u8{
        "-DSQLITE_ENABLE_FTS3=1",
        "-DSQLITE_ENABLE_FTS3_PARENTHESIS=1",
        "-DSQLITE_ENABLE_FTS3_TOKENIZER=1",
        "-DSQLITE_ENABLE_FTS4=1",
        "-DSQLITE_ENABLE_FTS5=1",
        // "-DSQLITE_ENABLE_ICU=1",
        "-DSQLITE_ENABLE_JSON1=1",
        "-DSQLITE_DQS=0",
    };
    libsqlite3.linkLibC();
    libsqlite3.addIncludePath("lib/sqlite-amalgamation-3410000/");
    libsqlite3.addCSourceFile("lib/sqlite-amalgamation-3410000/sqlite3.c", &libsqlilte_cflags);
    libsqlite3.install();

    const libsqlite3_tests = b.addTest(.{
        .root_source_file = .{.path = "src/sqlite.zig"},
        .target = target,
        .optimize = optimize,
    });
    libsqlite3_tests.linkLibrary(libsqlite3);
    libsqlite3_tests.addIncludePath("lib/sqlite-amalgamation-3410000/");

    const libsqlite3_test_step = b.step("sqlite", "Run unit tests for sqlite");
    libsqlite3_test_step.dependOn(&libsqlite3_tests.step);

    const bomtool = b.addExecutable(.{
        .name = "bomtool", 
        .root_source_file = .{.path = "src/bomtool.zig"},
        .target = target,
        .optimize = optimize,
    });
    bomtool.linkLibC();
    bomtool.linkSystemLibrary("curl");
    bomtool.install();

    const bomtool_cmd = bomtool.run();
    bomtool_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        bomtool_cmd.addArgs(args);
    }

    const run_step = b.step("bomtool", "Run the app");
    run_step.dependOn(&bomtool_cmd.step);

    const dbtool = b.addExecutable(.{
        .name = "dbtool", 
        .root_source_file = .{.path = "src/dbtool.zig"},
        .target = target,
        .optimize = optimize,
    });
    dbtool.linkLibC();
    dbtool.linkSystemLibrary("curl");
    dbtool.addIncludePath("lib/sqlite-amalgamation-3410000/");
    dbtool.linkLibrary(libsqlite3);
    dbtool.install();

    const dbtool_cmd = dbtool.run();
    dbtool_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        dbtool_cmd.addArgs(args);
    }

    const dbtool_run_step = b.step("dbtool", "Run the db builder");
    dbtool_run_step.dependOn(&dbtool_cmd.step);

    const bomtool_tests = b.addTest(.{
        .root_source_file = .{.path = "src/boomtool.zig"},
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&bomtool_tests.step);
}
