const std = @import("std");
const Compiler = @import("Compiler.zig");

const CompileTarget = Compiler.CompileTarget;
const CompileOptions = Compiler.CompileOptions;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        printUsage(args[0]);
        return error.InvalidArguments;
    }

    var options = CompileOptions{};
    var source_file: ?[]const u8 = null;
    
    // Parse command line arguments
    var i: usize = 1;
    while (i < args.len) {
        const arg = args[i];
        
        if (std.mem.eql(u8, arg, "--target")) {
            i += 1;
            if (i >= args.len) {
                std.debug.print("Error: --target requires a value\n", .{});
                return error.InvalidArguments;
            }
            options.target = parseTarget(args[i]) orelse {
                std.debug.print("Error: Invalid target '{s}'. Valid targets: linux-bpf, solana-bpf, bpf-vm\n", .{args[i]});
                return error.InvalidArguments;
            };
        } else if (std.mem.eql(u8, arg, "--generate-idl")) {
            options.generate_idl = true;
        } else if (std.mem.eql(u8, arg, "--enable-vm-testing")) {
            options.enable_vm_testing = true;
        } else if (std.mem.eql(u8, arg, "--output-dir")) {
            i += 1;
            if (i >= args.len) {
                std.debug.print("Error: --output-dir requires a value\n", .{});
                return error.InvalidArguments;
            }
            options.output_directory = args[i];
        } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            printUsage(args[0]);
            return;
        } else if (source_file == null) {
            source_file = arg;
        } else {
            std.debug.print("Error: Unknown argument '{s}'\n", .{arg});
            return error.InvalidArguments;
        }
        
        i += 1;
    }

    const source_path = source_file orelse {
        std.debug.print("Error: No source file specified\n", .{});
        printUsage(args[0]);
        return error.InvalidArguments;
    };

    std.debug.print("Compiling {s} for target: {s}...\n", .{ source_path, targetToString(options.target) });

    // Read source file
    const source = std.fs.cwd().readFileAlloc(allocator, source_path, std.math.maxInt(usize)) catch |err| {
        std.debug.print("Error reading file '{s}': {}\n", .{ source_path, err });
        return err;
    };
    defer allocator.free(source);

    // Compile source to BPF bytecode
    var compiler = Compiler.Compiler.initWithOptions(allocator, source, options);
    defer compiler.deinit();
    
    const bpf_bytecode = compiler.compile() catch |err| {
        std.debug.print("Compilation failed: {}\n", .{err});
        
        // Print any error messages
        const errors = compiler.getErrors();
        if (errors.len > 0) {
            std.debug.print("Error details:\n", .{});
            for (errors) |error_msg| {
                std.debug.print("  - {s}\n", .{error_msg});
            }
        }
        return err;
    };
    defer allocator.free(bpf_bytecode);

    // Generate output files
    const base_name = std.fs.path.stem(source_path);
    const output_dir = options.output_directory orelse std.fs.path.dirname(source_path) orelse ".";
    
    // Write BPF bytecode
    const bpf_path = try std.fmt.allocPrint(allocator, "{s}/{s}.bpf", .{ output_dir, base_name });
    defer allocator.free(bpf_path);
    
    try std.fs.cwd().writeFile(.{ .sub_path = bpf_path, .data = bpf_bytecode });
    std.debug.print("Successfully compiled to {s}\n", .{bpf_path});
    std.debug.print("Generated {d} bytes of BPF bytecode\n", .{bpf_bytecode.len});
    
    // Generate IDL file if requested
    if (options.generate_idl) {
        if (try compiler.generateIdlJson()) |idl_json| {
            defer allocator.free(idl_json);
            
            const idl_path = try std.fmt.allocPrint(allocator, "{s}/{s}.json", .{ output_dir, base_name });
            defer allocator.free(idl_path);
            
            try std.fs.cwd().writeFile(.{ .sub_path = idl_path, .data = idl_json });
            std.debug.print("Generated IDL: {s}\n", .{idl_path});
        }
    }
    
    // Print target-specific information
    switch (options.target) {
        .LinuxBpf => {
            std.debug.print("Target: Linux BPF - ready for kernel loading\n", .{});
        },
        .SolanaBpf => {
            std.debug.print("Target: Solana BPF - ready for Solana deployment\n", .{});
        },
        .BpfVm => {
            std.debug.print("Target: BPF VM - tested in emulator\n", .{});
        },
    }
}

fn printUsage(program_name: []const u8) void {
    std.debug.print("Usage: {s} [options] <source_file>\n", .{program_name});
    std.debug.print("\n", .{});
    std.debug.print("Options:\n", .{});
    std.debug.print("  --target <target>      Compilation target (linux-bpf, solana-bpf, bpf-vm)\n", .{});
    std.debug.print("  --generate-idl         Generate Interface Definition Language (IDL) file\n", .{});
    std.debug.print("  --enable-vm-testing    Enable BPF VM testing during compilation\n", .{});
    std.debug.print("  --output-dir <dir>     Output directory for generated files\n", .{});
    std.debug.print("  --help, -h             Show this help message\n", .{});
    std.debug.print("\n", .{});
    std.debug.print("Targets:\n", .{});
    std.debug.print("  linux-bpf              Traditional Linux BPF (default)\n", .{});
    std.debug.print("  solana-bpf             Solana BPF runtime\n", .{});
    std.debug.print("  bpf-vm                 BPF VM emulation for testing\n", .{});
    std.debug.print("\n", .{});
    std.debug.print("Examples:\n", .{});
    std.debug.print("  {s} program.hc\n", .{program_name});
    std.debug.print("  {s} --target solana-bpf --generate-idl program.hc\n", .{program_name});
    std.debug.print("  {s} --target bpf-vm --enable-vm-testing program.hc\n", .{program_name});
}

fn parseTarget(target_str: []const u8) ?CompileTarget {
    if (std.mem.eql(u8, target_str, "linux-bpf")) {
        return .LinuxBpf;
    } else if (std.mem.eql(u8, target_str, "solana-bpf")) {
        return .SolanaBpf;
    } else if (std.mem.eql(u8, target_str, "bpf-vm")) {
        return .BpfVm;
    }
    return null;
}

fn targetToString(target: CompileTarget) []const u8 {
    return switch (target) {
        .LinuxBpf => "linux-bpf",
        .SolanaBpf => "solana-bpf",
        .BpfVm => "bpf-vm",
    };
}