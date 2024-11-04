const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "hello_world",
        .root_source_file = .{ .path = "src/main.hc" },
        .target = target,
        .optimize = optimize,
    });

    // Set BPF target
    exe.setTarget(.{
        .cpu_arch = .bpfel,
        .os_tag = .freestanding,
        .abi = .eabi,
    });

    // Add compiler flags for BPF
    exe.addCFlag("-target");
    exe.addCFlag("bpf");

    // Install the artifact
    b.installArtifact(exe);

    // Create run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the BPF program");
    run_step.dependOn(&run_cmd.step);
}