const std = @import("std");
const testing = std.testing;
const Lexer = @import("../src/Pible/Lexer.zig");

test "lexer basic tokens" {
    const source =
        \\U0 main() {
        \\    U64 x = 42;
        \\    return 0;
        \\}
    ;

    var lexer = Lexer.Lexer.init(testing.allocator, source);
    defer lexer.deinit();

    try lexer.scanTokens();

    const expected_types = [_]Lexer.TokenType{
        .U0,
        .Identifier, // main
        .LeftParen,
        .RightParen,
        .LeftBrace,
        .U64,
        .Identifier, // x
        .Equal,
        .NumberLiteral, // 42
        .Semicolon,
        .Return,
        .NumberLiteral, // 0
        .Semicolon,
        .RightBrace,
        .Eof,
    };

    try testing.expectEqual(expected_types.len, lexer.tokens.items.len);

    for (expected_types, 0..) |expected, i| {
        try testing.expectEqual(expected, lexer.tokens.items[i].type);
    }
}

test "lexer string literals" {
    const source = 
        \\"Hello, World!"
        \\"Test\nEscape"
    ;

    var lexer = Lexer.Lexer.init(testing.allocator, source);
    defer lexer.deinit();

    try lexer.scanTokens();

    try testing.expectEqual(@as(usize, 3), lexer.tokens.items.len); // 2 strings + EOF
    try testing.expectEqual(Lexer.TokenType.StringLiteral, lexer.tokens.items[0].type);
    try testing.expectEqual(Lexer.TokenType.StringLiteral, lexer.tokens.items[1].type);
}

test "lexer comments" {
    const source =
        \\// This is a comment
        \\U0 main() // Another comment
        \\{
        \\    return 0; // End comment
        \\}
    ;

    var lexer = Lexer.Lexer.init(testing.allocator, source);
    defer lexer.deinit();

    try lexer.scanTokens();

    const expected_types = [_]Lexer.TokenType{
        .U0,
        .Identifier, // main
        .LeftParen,
        .RightParen,
        .LeftBrace,
        .Return,
        .NumberLiteral,
        .Semicolon,
        .RightBrace,
        .Eof,
    };

    try testing.expectEqual(expected_types.len, lexer.tokens.items.len);
}