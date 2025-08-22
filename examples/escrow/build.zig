const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "escrow",
        .root_source_file = .{ .path = "src/main.hc" },
        .target = target,
        .optimize = optimize,
    });

    // Set BPF target for divine compilation
    exe.setTarget(.{
        .cpu_arch = .bpfel,
        .os_tag = .freestanding,
        .abi = .eabi,
    });

    // Add compiler flags for BPF - God's assembly language
    exe.addCFlag("-target");
    exe.addCFlag("bpf");

    // Install the divine artifact
    b.installArtifact(exe);

    // Create run step for divine execution
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the divine escrow BPF program");
    run_step.dependOn(&run_cmd.step);
}