const std = @import("std");
const Lexer = @import("Lexer.zig");
const Parser = @import("Parser.zig");
const CodeGen = @import("CodeGen.zig");

pub const CompileError = error{
    LexError,
    ParseError,
    CodeGenError,
};

pub const Compiler = struct {
    allocator: std.mem.Allocator,
    source: []const u8,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, source: []const u8) Self {
        return .{
            .allocator = allocator,
            .source = source,
        };
    }

    pub fn compile(self: *Self) ![]const u8 {
        var lexer = Lexer.Lexer.init(self.allocator, self.source);
        defer lexer.deinit();

        try lexer.scanTokens();

        var parser = Parser.Parser.init(self.allocator, lexer.tokens.items);
        const ast = try parser.parse();
        defer ast.deinit();

        var codegen = CodeGen.CodeGen.init(self.allocator);
        defer codegen.deinit();

        try codegen.generate(ast);

        var output = std.ArrayList(u8).init(self.allocator);
        errdefer output.deinit();

        for (codegen.program.instructions.items) |instruction| {
            const bytes = std.mem.asBytes(&instruction);
            try output.appendSlice(bytes);
        }

        return output.toOwnedSlice();
    }
};