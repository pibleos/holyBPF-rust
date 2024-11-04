const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add zbpf dependency
    const zbpf_dep = b.dependency("zbpf", .{
        .target = target,
        .optimize = optimize,
    });

    // Build the HolyC compiler
    const holyc_compiler = b.addExecutable(.{
        .name = "pible",
        .root_source_file = .{ .path = "src/Pible/Main.zig" },
        .target = target,
        .optimize = optimize,
    });
    holyc_compiler.root_module.addImport("zbpf", zbpf_dep.module("zbpf"));
    b.installArtifact(holyc_compiler);

    // Add custom step for compiling HolyC files
    const compile_holyc = struct {
        fn compile(
            b2: *std.Build,
            compiler_exe: *std.Build.Step.Compile,
            source_file: []const u8,
            name: []const u8,
        ) *std.Build.Step.Compile {
            const compile_step = b2.addExecutable(.{
                .name = name,
                .target = .{
                    .cpu_arch = .bpfel,
                    .os_tag = .freestanding,
                    .abi = .eabi,
                },
                .optimize = .ReleaseSmall,
            });

            const run_holyc = b2.addRunArtifact(compiler_exe);
            run_holyc.addArg(source_file);
            compile_step.step.dependOn(&run_holyc.step);

            compile_step.linkLibC();
            compile_step.addCFlag("-target");
            compile_step.addCFlag("bpf");

            return compile_step;
        }
    }.compile;

    // Build examples
    inline for (.{
        .{ "hello-world", "examples/hello-world/src/main.hc" },
    }) |example| {
        const name = example[0];
        const source = example[1];

        const example_exe = compile_holyc(b, holyc_compiler, source, name);
        const install_example = b.addInstallArtifact(example_exe, .{});

        const example_step = b.step(name, "Build " ++ name ++ " example");
        example_step.dependOn(&install_example.step);
    }

    // Add test step
    const test_step = b.step("test", "Run HolyC compiler tests");
    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/Pible/Tests.zig" },
        .target = target,
        .optimize = optimize,
    });
    tests.root_module.addImport("zbpf", zbpf_dep.module("zbpf"));
    test_step.dependOn(&b.addRunArtifact(tests).step);
}
