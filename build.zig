const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build the HolyC compiler
    const holyc_compiler = b.addExecutable(.{
        .name = "pible",
        .root_source_file = .{ .cwd_relative = "src/Pible/Main.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(holyc_compiler);

    // Add custom step for compiling HolyC files
    const compile_holyc = struct {
        fn compile(
            b2: *std.Build,
            compiler_exe: *std.Build.Step.Compile,
            source_file: []const u8,
            name: []const u8,
        ) *std.Build.Step.InstallFile {
            // Run HolyC compiler to generate BPF bytecode
            const run_holyc = b2.addRunArtifact(compiler_exe);
            run_holyc.addArg(source_file);

            // The HolyC compiler generates a .bpf file next to the source
            const bpf_file = b2.fmt("{s}.bpf", .{source_file});
            
            // Install the generated BPF file as an artifact
            const install_bpf = b2.addInstallFile(.{ .cwd_relative = bpf_file }, b2.fmt("bin/{s}.bpf", .{name}));
            install_bpf.step.dependOn(&run_holyc.step);

            return install_bpf;
        }
    }.compile;

    // Build examples
    inline for (.{
        .{ "hello-world", "examples/hello-world/src/main.hc" },
        .{ "escrow", "examples/escrow/src/main.hc" },
        .{ "solana-token", "examples/solana-token/src/main.hc" },
    }) |example| {
        const name = example[0];
        const source = example[1];

        const install_bpf = compile_holyc(b, holyc_compiler, source, name);

        const example_step = b.step(name, "Build " ++ name ++ " example");
        example_step.dependOn(&install_bpf.step);
    }

    // Add test step
    const test_step = b.step("test", "Run HolyC compiler tests");
    
    // Add unit tests from src
    const tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/Pible/Tests.zig" },
        .target = target,
        .optimize = optimize,
    });
    test_step.dependOn(&b.addRunArtifact(tests).step);
    
    // Add simplified integration tests
    const integration_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "tests/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    test_step.dependOn(&b.addRunArtifact(integration_tests).step);
}
