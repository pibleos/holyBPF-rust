const std = @import("std");
const testing = std.testing;
const Compiler = @import("../src/Pible/Compiler.zig");

test "compile hello world" {
    const source =
        \\U0 main() {
        \\    PrintF("Hello, World!\n");
        \\    return 0;
        \\}
    ;

    var compiler = Compiler.Compiler.init(testing.allocator, source);
    const bytecode = try compiler.compile();
    defer testing.allocator.free(bytecode);

    try testing.expect(bytecode.len > 0);
}

test "compile arithmetic" {
    const source =
        \\U0 calc() {
        \\    U64 result = 2 + 3 * 4;
        \\    PrintF("Result: %d\n", result);
        \\    return 0;
        \\}
    ;

    var compiler = Compiler.Compiler.init(testing.allocator, source);
    const bytecode = try compiler.compile();
    defer testing.allocator.free(bytecode);

    try testing.expect(bytecode.len > 0);
}

test "compile error handling" {
    const invalid_source =
        \\U0 main() {
        \\    invalid_function();
        \\    return 0
        \\} // Missing semicolon
    ;

    var compiler = Compiler.Compiler.init(testing.allocator, invalid_source);
    try testing.expectError(error.ParseError, compiler.compile());
}