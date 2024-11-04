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
        return error.InvalidArguments;
    }

    const source = try std.fs.cwd().readFileAlloc(allocator, args[1], std.math.maxInt(usize));
    defer allocator.free(source);

    var compiler = Compiler.init(allocator, source);
    const bpf_bytecode = try compiler.compile();
    defer allocator.free(bpf_bytecode);

    const out_path = try std.fmt.allocPrint(allocator, "{s}.bpf", .{args[1]});
    defer allocator.free(out_path);

    try std.fs.cwd().writeFile(out_path, bpf_bytecode);
    std.debug.print("Successfully compiled to {s}\n", .{out_path});
}