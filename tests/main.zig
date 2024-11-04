const std = @import("std");

test {
    std.testing.refAllDecls(@This());
    _ = @import("lexer_test.zig");
    _ = @import("parser_test.zig");
    _ = @import("codegen_test.zig");
    _ = @import("compiler_test.zig");
    _ = @import("integration_test.zig");
}