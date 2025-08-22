const std = @import("std");

test {
    std.testing.refAllDecls(@This());
    _ = @import("test_lexer.zig");
}