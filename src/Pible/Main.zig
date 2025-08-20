const std = @import("std");
const Compiler = @import("Compiler.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        std.debug.print("Usage: {s} <source_file>\n", .{args[0]});
        std.debug.print("  Compiles HolyC source file to BPF bytecode\n");
        return error.InvalidArguments;
    }

    const source_path = args[1];
    std.debug.print("Compiling {s}...\n", .{source_path});

    // Read source file
    const source = std.fs.cwd().readFileAlloc(allocator, source_path, std.math.maxInt(usize)) catch |err| {
        std.debug.print("Error reading file '{s}': {}\n", .{ source_path, err });
        return err;
    };
    defer allocator.free(source);

    // Compile source to BPF bytecode
    var compiler = Compiler.Compiler.init(allocator, source);
    defer compiler.deinit();
    
    const bpf_bytecode = compiler.compile() catch |err| {
        std.debug.print("Compilation failed: {}\n", .{err});
        
        // Print any error messages
        const errors = compiler.getErrors();
        if (errors.len > 0) {
            std.debug.print("Error details:\n");
            for (errors) |error_msg| {
                std.debug.print("  - {s}\n", .{error_msg});
            }
        }
        return err;
    };
    defer allocator.free(bpf_bytecode);

    // Generate output filename
    const out_path = try std.fmt.allocPrint(allocator, "{s}.bpf", .{source_path});
    defer allocator.free(out_path);

    // Write bytecode to output file
    try std.fs.cwd().writeFile(out_path, bpf_bytecode);
    
    std.debug.print("Successfully compiled to {s}\n", .{out_path});
    std.debug.print("Generated {d} bytes of BPF bytecode\n", .{bpf_bytecode.len});
}