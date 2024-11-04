const std = @import("std");
const testing = std.testing;
const Parser = @import("../src/Pible/Parser.zig");
const Lexer = @import("../src/Pible/Lexer.zig");

test "parser function declaration" {
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

    try testing.expectEqual(Parser.NodeType.Program, ast.type);
    try testing.expectEqual(@as(usize, 1), ast.children.items.len);
    try testing.expectEqual(Parser.NodeType.FunctionDecl, ast.children.items[0].type);
}

test "parser if statement" {
    const source =
        \\U0 test() {
        \\    if (x > 0) {
        \\        return 1;
        \\    } else {
        \\        return 0;
        \\    }
        \\}
    ;

    var lexer = Lexer.Lexer.init(testing.allocator, source);
    defer lexer.deinit();
    try lexer.scanTokens();

    var parser = Parser.Parser.init(testing.allocator, lexer.tokens.items);
    const ast = try parser.parse();
    defer ast.deinit();

    const func_node = ast.children.items[0];
    const if_node = func_node.children.items[0];
    try testing.expectEqual(Parser.NodeType.IfStmt, if_node.type);
}

test "parser expression" {
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

    const func_node = ast.children.items[0];
    const return_node = func_node.children.items[0];
    try testing.expectEqual(Parser.NodeType.ReturnStmt, return_node.type);
    try testing.expectEqual(Parser.NodeType.BinaryExpr, return_node.children.items[0].type);
}