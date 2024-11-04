const std = @import("std");
const testing = std.testing;
const CodeGen = @import("../src/Pible/CodeGen.zig");
const Parser = @import("../src/Pible/Parser.zig");
const Lexer = @import("../src/Pible/Lexer.zig");

test "codegen simple function" {
    const source =
        \\U0 main() {
        \\    return 0;
        \\}
    ;

    var lexer = Lexer.Lexer.init(testing.allocator, source);
    defer lexer.deinit();
    try lexer.scanTokens();

    var parser = Parser.Parser.init(testing.allocator, lexer.tokens.items);
    const ast = try parser.parse();
    defer ast.deinit();

    var codegen = CodeGen.CodeGen.init(testing.allocator);
    defer codegen.deinit();

    try codegen.generate(ast);
    try testing.expect(codegen.program.instructions.items.len > 0);
}

test "codegen arithmetic" {
    const source =
        \\U0 calc() {
        \\    return 2 + 3 * 4;
        \\}
    ;

    var lexer = Lexer.Lexer.init(testing.allocator, source);
    defer lexer.deinit();
    try lexer.scanTokens();

    var parser = Parser.Parser.init(testing.allocator, lexer.tokens.items);
    const ast = try parser.parse();
    defer ast.deinit();

    var codegen = CodeGen.CodeGen.init(testing.allocator);
    defer codegen.deinit();

    try codegen.generate(ast);
    try testing.expect(codegen.program.instructions.items.len > 0);
}

test "codegen function call" {
    const source =
        \\U0 print(U64 x) {
        \\    return;
        \\}
        \\
        \\U0 main() {
        \\    print(42);
        \\    return;
        \\}
    ;

    var lexer = Lexer.Lexer.init(testing.allocator, source);
    defer lexer.deinit();
    try lexer.scanTokens();

    var parser = Parser.Parser.init(testing.allocator, lexer.tokens.items);
    const ast = try parser.parse();
    defer ast.deinit();

    var codegen = CodeGen.CodeGen.init(testing.allocator);
    defer codegen.deinit();

    try codegen.generate(ast);
    try testing.expect(codegen.program.instructions.items.len > 0);
}