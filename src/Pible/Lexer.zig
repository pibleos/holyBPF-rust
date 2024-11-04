const std = @import("std");

pub const TokenType = enum {
    // Keywords
    U0,
    U8,
    U16,
    U32,
    U64,
    I8,
    I16,
    I32,
    I64,
    F64,
    Bool,
    If,
    Else,
    While,
    For,
    Return,
    Break,
    Continue,
    Class,
    Public,
    Private,

    // Symbols
    LeftParen,
    RightParen,
    LeftBrace,
    RightBrace,
    Semicolon,
    Comma,
    Dot,
    Plus,
    Minus,
    Star,
    Slash,
    Equal,
    EqualEqual,
    Bang,
    BangEqual,
    Less,
    LessEqual,
    Greater,
    GreaterEqual,
    And,
    Or,

    // Literals
    Identifier,
    StringLiteral,
    NumberLiteral,
    True,
    False,

    // Special
    Eof,
    Invalid,
};

pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    line: usize,
    column: usize,
};

pub const Lexer = struct {
    source: []const u8,
    tokens: std.ArrayList(Token),
    current: usize = 0,
    line: usize = 1,
    column: usize = 1,
    start: usize = 0,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, source: []const u8) Self {
        return .{
            .source = source,
            .tokens = std.ArrayList(Token).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.tokens.deinit();
    }

    pub fn scanTokens(self: *Self) !void {
        while (!self.isAtEnd()) {
            self.start = self.current;
            try self.scanToken();
        }

        try self.tokens.append(Token{
            .type = .Eof,
            .lexeme = "",
            .line = self.line,
            .column = self.column,
        });
    }

    fn scanToken(self: *Self) !void {
        const c = self.advance();
        switch (c) {
            '(' => try self.addToken(.LeftParen),
            ')' => try self.addToken(.RightParen),
            '{' => try self.addToken(.LeftBrace),
            '}' => try self.addToken(.RightBrace),
            ';' => try self.addToken(.Semicolon),
            ',' => try self.addToken(.Comma),
            '.' => try self.addToken(.Dot),
            '+' => try self.addToken(.Plus),
            '-' => try self.addToken(.Minus),
            '*' => try self.addToken(.Star),
            '/' => {
                if (self.match('/')) {
                    // Comment until end of line
                    while (!self.isAtEnd() and self.peek() != '\n') _ = self.advance();
                } else {
                    try self.addToken(.Slash);
                }
            },
            '=' => try self.addToken(if (self.match('=')) .EqualEqual else .Equal),
            '!' => try self.addToken(if (self.match('=')) .BangEqual else .Bang),
            '<' => try self.addToken(if (self.match('=')) .LessEqual else .Less),
            '>' => try self.addToken(if (self.match('=')) .GreaterEqual else .Greater),
            '&' => if (self.match('&')) try self.addToken(.And),
            '|' => if (self.match('|')) try self.addToken(.Or),
            ' ', '\r', '\t' => {},
            '\n' => {
                self.line += 1;
                self.column = 1;
            },
            '"' => try self.string(),
            else => {
                if (isDigit(c)) {
                    try self.number();
                } else if (isAlpha(c)) {
                    try self.identifier();
                } else {
                    try self.addToken(.Invalid);
                }
            },
        }
    }

    fn string(self: *Self) !void {
        while (!self.isAtEnd() and self.peek() != '"') {
            if (self.peek() == '\n') self.line += 1;
            _ = self.advance();
        }

        if (self.isAtEnd()) {
            try self.addToken(.Invalid);
            return;
        }

        _ = self.advance(); // Closing quote
        try self.addToken(.StringLiteral);
    }

    fn number(self: *Self) !void {
        while (!self.isAtEnd() and isDigit(self.peek())) _ = self.advance();

        if (!self.isAtEnd() and self.peek() == '.' and isDigit(self.peekNext())) {
            _ = self.advance();
            while (!self.isAtEnd() and isDigit(self.peek())) _ = self.advance();
        }

        try self.addToken(.NumberLiteral);
    }

    fn identifier(self: *Self) !void {
        while (!self.isAtEnd() and isAlphaNumeric(self.peek())) _ = self.advance();

        const text = self.source[self.start..self.current];
        const tokenType = getKeywordType(text);
        try self.addToken(tokenType);
    }

    fn getKeywordType(text: []const u8) TokenType {
        const keywords = std.ComptimeStringMap(TokenType, .{
            .{ "U0", .U0 },
            .{ "U8", .U8 },
            .{ "U16", .U16 },
            .{ "U32", .U32 },
            .{ "U64", .U64 },
            .{ "I8", .I8 },
            .{ "I16", .I16 },
            .{ "I32", .I32 },
            .{ "I64", .I64 },
            .{ "F64", .F64 },
            .{ "Bool", .Bool },
            .{ "if", .If },
            .{ "else", .Else },
            .{ "while", .While },
            .{ "for", .For },
            .{ "return", .Return },
            .{ "break", .Break },
            .{ "continue", .Continue },
            .{ "class", .Class },
            .{ "public", .Public },
            .{ "private", .Private },
            .{ "true", .True },
            .{ "false", .False },
        });

        return keywords.get(text) orelse .Identifier;
    }

    fn addToken(self: *Self, token_type: TokenType) !void {
        const lexeme = self.source[self.start..self.current];
        try self.tokens.append(Token{
            .type = token_type,
            .lexeme = lexeme,
            .line = self.line,
            .column = self.column,
        });
        self.column += lexeme.len;
    }

    fn advance(self: *Self) u8 {
        self.current += 1;
        return self.source[self.current - 1];
    }

    fn match(self: *Self, expected: u8) bool {
        if (self.isAtEnd()) return false;
        if (self.source[self.current] != expected) return false;

        self.current += 1;
        return true;
    }

    fn peek(self: *Self) u8 {
        if (self.isAtEnd()) return 0;
        return self.source[self.current];
    }

    fn peekNext(self: *Self) u8 {
        if (self.current + 1 >= self.source.len) return 0;
        return self.source[self.current + 1];
    }

    fn isAtEnd(self: *Self) bool {
        return self.current >= self.source.len;
    }
};

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn isAlpha(c: u8) bool {
    return (c >= 'a' and c <= 'z') or
        (c >= 'A' and c <= 'Z') or
        c == '_';
}

fn isAlphaNumeric(c: u8) bool {
    return isAlpha(c) or isDigit(c);
}