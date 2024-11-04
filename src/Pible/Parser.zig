const std = @import("std");
const Lexer = @import("Lexer.zig");
const Token = Lexer.Token;
const TokenType = Lexer.TokenType;

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

    pub fn init(allocator: std.mem.Allocator, node_type: NodeType, token: Token) !*Node {
        const node = try allocator.create(Node);
        node.* = .{
            .type = node_type,
            .token = token,
            .children = std.ArrayList(*Node).init(allocator),
            .allocator = allocator,
        };
        return node;
    }

    pub fn deinit(self: *Node) void {
        for (self.children.items) |child| {
            child.deinit();
        }
        self.children.deinit();
        self.allocator.destroy(self);
    }

    pub fn addChild(self: *Node, child: *Node) !void {
        try self.children.append(child);
    }
};

// Rest of Parser implementation remains the same as before
// Just moved to new location