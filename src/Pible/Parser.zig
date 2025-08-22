const std = @import("std");
const Lexer = @import("Lexer.zig");
const Token = Lexer.Token;
pub const TokenType = Lexer.TokenType;

pub const ParseError = error{
    ParseError,
    OutOfMemory,
};

pub const NodeType = enum {
    Program,
    FunctionDecl,
    VarDecl,
    Block,
    ExprStmt,
    ReturnStmt,
    IfStmt,
    WhileStmt,
    BinaryExpr,
    UnaryExpr,
    CallExpr,
    Literal,
    Identifier,
};

pub const Node = struct {
    type: NodeType,
    token: Token,
    children: std.ArrayList(*Node),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, node_type: NodeType, token: Token) ParseError!*Node {
        const node = try allocator.create(Node);
        node.* = .{
            .type = node_type,
            .token = token,
            .children = std.ArrayList(*Node){},
            .allocator = allocator,
        };
        return node;
    }

    pub fn deinit(self: *Node) void {
        for (self.children.items) |child| {
            child.deinit();
        }
        self.children.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    pub fn addChild(self: *Node, child: *Node) ParseError!void {
        try self.children.append(self.allocator, child);
    }
};

pub const Parser = struct {
    tokens: []const Token,
    current: usize = 0,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, tokens: []const Token) Self {
        return .{
            .tokens = tokens,
            .allocator = allocator,
        };
    }

    pub fn parse(self: *Self) ParseError!*Node {
        const program = try Node.init(self.allocator, .Program, Token{
            .type = .Eof,
            .lexeme = "",
            .line = 1,
            .column = 1,
        });
        errdefer program.deinit();

        while (!self.isAtEnd()) {
            if (self.peek().type == .Eof) break;
            const decl = self.declaration() catch |err| {
                // Clean up program node if declaration fails
                return err;
            };
            try program.addChild(decl);
        }

        return program;
    }

    fn declaration(self: *Self) ParseError!*Node {
        // Handle export keyword
        if (self.match(.Export)) {
            return self.declaration(); // Skip export for now, just parse the following declaration
        }
        
        if (self.match(.U0) or self.match(.U8) or self.match(.U16) or 
            self.match(.U32) or self.match(.U64) or self.match(.I8) or 
            self.match(.I16) or self.match(.I32) or self.match(.I64) or self.match(.F64)) {
            
            // Look ahead to determine if this is a function or variable declaration
            if (self.check(.Identifier)) {
                const saved_current = self.current;
                _ = self.advance(); // consume identifier
                
                if (self.check(.LeftParen)) {
                    // It's a function declaration, reset and parse as function
                    self.current = saved_current;
                    return self.functionDeclaration();
                } else {
                    // It's a variable declaration, reset and parse as variable
                    self.current = saved_current;
                    return self.varDeclaration();
                }
            } else {
                return error.ParseError;
            }
        }
        return self.statement();
    }

    /// Parse function parameter list and add parameter nodes to function
    fn parseParameters(self: *Self, func: *Node) ParseError!void {
        if (!self.check(.RightParen)) {
            while (true) {
                // Parameter type must be specified
                if (!self.match(.U0) and !self.match(.U8) and !self.match(.U16) and 
                    !self.match(.U32) and !self.match(.U64) and !self.match(.I8) and 
                    !self.match(.I16) and !self.match(.I32) and !self.match(.I64) and !self.match(.F64)) {
                    return error.ParseError;
                }
                _ = self.previous(); // paramType - consume but not use for now
                
                // Handle pointer types (optional *)
                if (self.match(.Star)) {
                    // This is a pointer type, continue
                }
                
                // Parameter name
                const paramName = try self.consume(.Identifier, "Expected parameter name");
                
                // Create parameter node
                const param = try Node.init(self.allocator, .VarDecl, paramName);
                func.addChild(param) catch |err| {
                    // Clean up parameter node if adding fails
                    param.deinit(self.allocator);
                    return err;
                };
                
                if (!self.match(.Comma)) break;
            }
        }
    }

    fn functionDeclaration(self: *Self) ParseError!*Node {
        _ = self.previous(); // returnType - consume but not use for now
        const name = try self.consume(.Identifier, "Expected function name");
        
        const func = try Node.init(self.allocator, .FunctionDecl, name);
        errdefer func.deinit();
        
        _ = try self.consume(.LeftParen, "Expected '(' after function name");
        
        // Parse parameters using helper method
        try self.parseParameters(func);
        
        _ = try self.consume(.RightParen, "Expected ')' after parameters");
        _ = try self.consume(.LeftBrace, "Expected '{' before function body");
        
        const body = try self.block();
        try func.addChild(body);
        
        return func;
    }

    fn statement(self: *Self) ParseError!*Node {
        if (self.match(.If)) return self.ifStatement();
        if (self.match(.While)) return self.whileStatement();
        if (self.match(.For)) return self.forStatement();
        if (self.match(.Return)) return self.returnStatement();
        if (self.match(.LeftBrace)) return self.block();
        
        // Variable declaration
        if (self.match(.U0) or self.match(.U8) or self.match(.U16) or 
            self.match(.U32) or self.match(.U64) or self.match(.I8) or 
            self.match(.I16) or self.match(.I32) or self.match(.I64) or self.match(.F64)) {
            return self.varDeclaration();
        }
        
        return self.expressionStatement();
    }

    fn ifStatement(self: *Self) ParseError!*Node {
        const ifToken = self.previous();
        const stmt = try Node.init(self.allocator, .IfStmt, ifToken);
        errdefer stmt.deinit();
        
        _ = try self.consume(.LeftParen, "Expected '(' after 'if'");
        const condition = try self.expression();
        try stmt.addChild(condition);
        _ = try self.consume(.RightParen, "Expected ')' after if condition");
        
        const thenBranch = try self.statement();
        try stmt.addChild(thenBranch);
        
        if (self.match(.Else)) {
            const elseBranch = try self.statement();
            try stmt.addChild(elseBranch);
        }
        
        return stmt;
    }

    fn whileStatement(self: *Self) ParseError!*Node {
        const whileToken = self.previous();
        const stmt = try Node.init(self.allocator, .WhileStmt, whileToken);
        errdefer stmt.deinit();
        
        _ = try self.consume(.LeftParen, "Expected '(' after 'while'");
        const condition = try self.expression();
        try stmt.addChild(condition);
        _ = try self.consume(.RightParen, "Expected ')' after while condition");
        
        const body = try self.statement();
        try stmt.addChild(body);
        
        return stmt;
    }

    fn forStatement(self: *Self) ParseError!*Node {
        const forToken = self.previous();
        const stmt = try Node.init(self.allocator, .WhileStmt, forToken); // Use WhileStmt for now
        errdefer stmt.deinit();
        
        _ = try self.consume(.LeftParen, "Expected '(' after 'for'");
        
        // Initializer
        const initializer = if (self.match(.Semicolon)) null
        else if (self.match(.U0) or self.match(.U8) or self.match(.U16) or 
                 self.match(.U32) or self.match(.U64) or self.match(.I8) or 
                 self.match(.I16) or self.match(.I32) or self.match(.I64) or self.match(.F64))
            try self.varDeclaration()
        else try self.expressionStatement();
        
        if (initializer) |init_expr| try stmt.addChild(init_expr);
        
        // Condition
        const condition = if (!self.check(.Semicolon)) try self.expression() else null;
        _ = try self.consume(.Semicolon, "Expected ';' after for loop condition");
        if (condition) |cond| try stmt.addChild(cond);
        
        // Increment
        const increment = if (!self.check(.RightParen)) try self.expression() else null;
        _ = try self.consume(.RightParen, "Expected ')' after for clauses");
        if (increment) |inc| try stmt.addChild(inc);
        
        const body = try self.statement();
        try stmt.addChild(body);
        
        return stmt;
    }

    fn returnStatement(self: *Self) ParseError!*Node {
        const returnToken = self.previous();
        const stmt = try Node.init(self.allocator, .ReturnStmt, returnToken);
        errdefer stmt.deinit();
        
        if (!self.check(.Semicolon)) {
            const value = try self.expression();
            try stmt.addChild(value);
        }
        
        _ = try self.consume(.Semicolon, "Expected ';' after return value");
        return stmt;
    }

    fn varDeclaration(self: *Self) ParseError!*Node {
        _ = self.previous(); // typeToken - consume but not use for now
        const name = try self.consume(.Identifier, "Expected variable name");
        
        const varDecl = try Node.init(self.allocator, .VarDecl, name);
        errdefer varDecl.deinit();
        
        if (self.match(.Equal)) {
            const initializer = try self.expression();
            try varDecl.addChild(initializer);
        }
        
        _ = try self.consume(.Semicolon, "Expected ';' after variable declaration");
        return varDecl;
    }

    fn block(self: *Self) ParseError!*Node {
        const blockNode = try Node.init(self.allocator, .Block, Token{
            .type = .LeftBrace,
            .lexeme = "{",
            .line = self.peek().line,
            .column = self.peek().column,
        });
        errdefer blockNode.deinit();
        
        while (!self.check(.RightBrace) and !self.isAtEnd()) {
            const stmt = try self.declaration();
            try blockNode.addChild(stmt);
        }
        
        _ = try self.consume(.RightBrace, "Expected '}' after block");
        return blockNode;
    }

    fn expressionStatement(self: *Self) ParseError!*Node {
        const expr = try self.expression();
        _ = try self.consume(.Semicolon, "Expected ';' after expression");
        
        const exprStmt = try Node.init(self.allocator, .ExprStmt, Token{
            .type = .Semicolon,
            .lexeme = ";",
            .line = self.previous().line,
            .column = self.previous().column,
        });
        errdefer exprStmt.deinit();
        try exprStmt.addChild(expr);
        return exprStmt;
    }

    fn expression(self: *Self) ParseError!*Node {
        return self.logical_or();
    }

    fn logical_or(self: *Self) ParseError!*Node {
        var expr = try self.logical_and();
        
        while (self.match(.Or)) {
            const operator = self.previous();
            const right = try self.logical_and();
            const binary = try Node.init(self.allocator, .BinaryExpr, operator);
            errdefer binary.deinit();
            try binary.addChild(expr);
            try binary.addChild(right);
            expr = binary;
        }
        
        return expr;
    }

    fn logical_and(self: *Self) ParseError!*Node {
        var expr = try self.equality();
        
        while (self.match(.And)) {
            const operator = self.previous();
            const right = try self.equality();
            const binary = try Node.init(self.allocator, .BinaryExpr, operator);
            errdefer binary.deinit();
            try binary.addChild(expr);
            try binary.addChild(right);
            expr = binary;
        }
        
        return expr;
    }

    fn equality(self: *Self) ParseError!*Node {
        var expr = try self.comparison();
        
        while (self.match(.BangEqual) or self.match(.EqualEqual)) {
            const operator = self.previous();
            const right = try self.comparison();
            const binary = try Node.init(self.allocator, .BinaryExpr, operator);
            errdefer binary.deinit();
            try binary.addChild(expr);
            try binary.addChild(right);
            expr = binary;
        }
        
        return expr;
    }

    fn comparison(self: *Self) ParseError!*Node {
        var expr = try self.term();
        
        while (self.match(.Greater) or self.match(.GreaterEqual) or 
               self.match(.Less) or self.match(.LessEqual)) {
            const operator = self.previous();
            const right = try self.term();
            const binary = try Node.init(self.allocator, .BinaryExpr, operator);
            errdefer binary.deinit();
            try binary.addChild(expr);
            try binary.addChild(right);
            expr = binary;
        }
        
        return expr;
    }

    fn term(self: *Self) ParseError!*Node {
        var expr = try self.factor();
        
        while (self.match(.Minus) or self.match(.Plus)) {
            const operator = self.previous();
            const right = try self.factor();
            const binary = try Node.init(self.allocator, .BinaryExpr, operator);
            errdefer binary.deinit();
            try binary.addChild(expr);
            try binary.addChild(right);
            expr = binary;
        }
        
        return expr;
    }

    fn factor(self: *Self) ParseError!*Node {
        var expr = try self.unary();
        
        while (self.match(.Slash) or self.match(.Star)) {
            const operator = self.previous();
            const right = try self.unary();
            const binary = try Node.init(self.allocator, .BinaryExpr, operator);
            errdefer binary.deinit();
            try binary.addChild(expr);
            try binary.addChild(right);
            expr = binary;
        }
        
        return expr;
    }

    fn unary(self: *Self) ParseError!*Node {
        if (self.match(.Bang) or self.match(.Minus)) {
            const operator = self.previous();
            const right = try self.unary();
            const unary_expr = try Node.init(self.allocator, .UnaryExpr, operator);
            errdefer unary_expr.deinit();
            try unary_expr.addChild(right);
            return unary_expr;
        }
        
        return self.call();
    }

    fn call(self: *Self) ParseError!*Node {
        var expr = try self.primary();
        
        while (true) {
            if (self.match(.LeftParen)) {
                expr = try self.finishCall(expr);
            } else {
                break;
            }
        }
        
        return expr;
    }

    fn finishCall(self: *Self, callee: *Node) ParseError!*Node {
        const call_expr = try Node.init(self.allocator, .CallExpr, Token{
            .type = .LeftParen,
            .lexeme = "(",
            .line = self.previous().line,
            .column = self.previous().column,
        });
        errdefer call_expr.deinit();
        try call_expr.addChild(callee);
        
        if (!self.check(.RightParen)) {
            while (true) {
                const arg = try self.expression();
                try call_expr.addChild(arg);
                if (!self.match(.Comma)) break;
            }
        }
        
        _ = try self.consume(.RightParen, "Expected ')' after arguments");
        return call_expr;
    }

    fn primary(self: *Self) ParseError!*Node {
        if (self.match(.True) or self.match(.False)) {
            return Node.init(self.allocator, .Literal, self.previous());
        }
        
        if (self.match(.NumberLiteral)) {
            return Node.init(self.allocator, .Literal, self.previous());
        }
        
        if (self.match(.StringLiteral)) {
            return Node.init(self.allocator, .Literal, self.previous());
        }
        
        if (self.match(.Identifier) or self.match(.PrintF)) {
            return Node.init(self.allocator, .Identifier, self.previous());
        }
        
        if (self.match(.LeftParen)) {
            const expr = try self.expression();
            _ = try self.consume(.RightParen, "Expected ')' after expression");
            return expr;
        }
        
        return error.ParseError;
    }

    // Helper methods
    fn match(self: *Self, tokenType: TokenType) bool {
        if (self.check(tokenType)) {
            _ = self.advance();
            return true;
        }
        return false;
    }

    fn check(self: *Self, tokenType: TokenType) bool {
        if (self.isAtEnd()) return false;
        return self.peek().type == tokenType;
    }

    fn advance(self: *Self) Token {
        if (!self.isAtEnd()) self.current += 1;
        return self.previous();
    }

    fn isAtEnd(self: *Self) bool {
        return self.peek().type == .Eof;
    }

    fn peek(self: *Self) Token {
        return self.tokens[self.current];
    }

    fn previous(self: *Self) Token {
        return self.tokens[self.current - 1];
    }

    fn consume(self: *Self, tokenType: TokenType, message: []const u8) ParseError!Token {
        if (self.check(tokenType)) return self.advance();
        
        std.debug.print("Parse error at line {d}: {s}\n", .{ self.peek().line, message });
        return error.ParseError;
    }
};