const std = @import("std");
const testing = std.testing;
const Compiler = @import("Compiler.zig");
const Lexer = @import("Lexer.zig");
const Parser = @import("Parser.zig");
const CodeGen = @import("CodeGen.zig");

test "lexer basic functionality" {
    const source = "U0 main() { return 0; }";
    
    var lexer = Lexer.Lexer.init(testing.allocator, source);
    defer lexer.deinit();
    
    try lexer.scanTokens();
    try testing.expect(lexer.tokens.items.len > 0);
    try testing.expectEqual(Lexer.TokenType.U0, lexer.tokens.items[0].type);
}

test "parser basic functionality" {
    const source = "U0 main() { return 0; }";
    
    var lexer = Lexer.Lexer.init(testing.allocator, source);
    defer lexer.deinit();
    try lexer.scanTokens();
    
    var parser = Parser.Parser.init(testing.allocator, lexer.tokens.items);
    const ast = try parser.parse();
    defer ast.deinit();
    
    try testing.expectEqual(Parser.NodeType.Program, ast.type);
    try testing.expect(ast.children.items.len > 0);
}

test "codegen basic functionality" {
    const source = "U0 main() { return 0; }";
    
    var lexer = Lexer.Lexer.init(testing.allocator, source);
    defer lexer.deinit();
    try lexer.scanTokens();
    
    var parser = Parser.Parser.init(testing.allocator, lexer.tokens.items);
    const ast = try parser.parse();
    defer ast.deinit();
    
    var codegen = CodeGen.CodeGen.init(testing.allocator);
    defer codegen.deinit();
    
    try codegen.generate(ast);
    try testing.expect(codegen.instructions.items.len > 0);
}

test "compiler end-to-end" {
    const source = 
        \\U0 main() {
        \\    U64 x = 42;
        \\    return x;
        \\}
    ;
    
    var compiler = Compiler.Compiler.init(testing.allocator, source);
    defer compiler.deinit();
    const bytecode = try compiler.compile();
    defer testing.allocator.free(bytecode);
    
    try testing.expect(bytecode.len > 0);
    try testing.expect(bytecode.len % 8 == 0); // BPF instructions are 8 bytes
}

test "arithmetic expression compilation" {
    const source = 
        \\U0 calc() {
        \\    return 2 + 3 * 4;
        \\}
    ;
    
    var compiler = Compiler.Compiler.init(testing.allocator, source);
    defer compiler.deinit();
    const bytecode = try compiler.compile();
    defer testing.allocator.free(bytecode);
    
    try testing.expect(bytecode.len > 0);
}

test "function with variables" {
    const source = 
        \\U0 test() {
        \\    U64 a = 10;
        \\    U64 b = 20;
        \\    U64 c = a + b;
        \\    return c;
        \\}
    ;
    
    var compiler = Compiler.Compiler.init(testing.allocator, source);
    defer compiler.deinit();
    const bytecode = try compiler.compile();
    defer testing.allocator.free(bytecode);
    
    try testing.expect(bytecode.len > 0);
}