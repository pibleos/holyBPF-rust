const std = @import("std");
const BpfVm = @import("../src/Pible/BpfVm.zig");
const CodeGen = @import("../src/Pible/CodeGen.zig");
const Compiler = @import("../src/Pible/Compiler.zig");

test "BPF VM basic execution" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Create simple BPF program: mov r0, 42; exit
    const instructions = [_]CodeGen.BpfInstruction{
        .{ .opcode = 0xb7, .dst_reg = 0, .src_reg = 0, .offset = 0, .imm = 42 }, // mov r0, 42
        .{ .opcode = 0x95, .dst_reg = 0, .src_reg = 0, .offset = 0, .imm = 0 },  // exit
    };
    
    var vm = BpfVm.BpfVm.init(allocator, &instructions);
    defer vm.deinit();
    
    const result = vm.execute() catch |err| switch (err) {
        BpfVm.BpfVmError.ProgramExit => {
            // Normal program exit
            try std.testing.expect(vm.registers[0] == 42);
            return;
        },
        else => return err,
    };
    
    try std.testing.expect(result.exit_code == 42);
}

test "Solana BPF compilation" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    const source = "U0 main() { return 0; }";
    
    var options = Compiler.CompileOptions{
        .target = .SolanaBpf,
        .generate_idl = true,
    };
    
    var compiler = Compiler.Compiler.initWithOptions(allocator, source, options);
    defer compiler.deinit();
    
    const bytecode = try compiler.compile();
    defer allocator.free(bytecode);
    
    try std.testing.expect(bytecode.len > 0);
    
    // Check IDL generation
    const idl_json = try compiler.generateIdlJson();
    if (idl_json) |json| {
        defer allocator.free(json);
        try std.testing.expect(json.len > 0);
        try std.testing.expect(std.mem.indexOf(u8, json, "version") != null);
    }
}

test "Multi-target compilation" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    const source = "U0 main() { PrintF(\"Hello, World!\\n\"); return 0; }";
    
    // Test Linux BPF target
    {
        var options = Compiler.CompileOptions{ .target = .LinuxBpf };
        var compiler = Compiler.Compiler.initWithOptions(allocator, source, options);
        defer compiler.deinit();
        
        const bytecode = try compiler.compile();
        defer allocator.free(bytecode);
        try std.testing.expect(bytecode.len > 0);
    }
    
    // Test Solana BPF target
    {
        var options = Compiler.CompileOptions{ .target = .SolanaBpf };
        var compiler = Compiler.Compiler.initWithOptions(allocator, source, options);
        defer compiler.deinit();
        
        const bytecode = try compiler.compile();
        defer allocator.free(bytecode);
        try std.testing.expect(bytecode.len > 0);
    }
    
    // Test BPF VM target
    {
        var options = Compiler.CompileOptions{ .target = .BpfVm };
        var compiler = Compiler.Compiler.initWithOptions(allocator, source, options);
        defer compiler.deinit();
        
        const bytecode = try compiler.compile();
        defer allocator.free(bytecode);
        try std.testing.expect(bytecode.len > 0);
    }
}