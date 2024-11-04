const std = @import("std");
const testing = std.testing;
const Compiler = @import("../src/Pible/Compiler.zig");

test "end to end compilation" {
    // Test complete program compilation and verification
    const source =
        \\U0 process_data(U64 *data, U64 len) {
        \\    U64 sum = 0;
        \\    for (U64 i = 0; i < len; i++) {
        \\        sum += data[i];
        \\    }
        \\    return sum;
        \\}
        \\
        \\U0 main() {
        \\    U64 data[] = {1, 2, 3, 4, 5};
        \\    U64 result = process_data(data, 5);
        \\    PrintF("Sum: %d\n", result);
        \\    return 0;
        \\}
    ;

    var compiler = Compiler.Compiler.init(testing.allocator, source);
    const bytecode = try compiler.compile();
    defer testing.allocator.free(bytecode);

    // Verify BPF bytecode structure
    try testing.expect(bytecode.len > 0);
    try testing.expect(bytecode.len % 8 == 0); // BPF instructions are 8 bytes
}

test "compile and verify multiple functions" {
    const source =
        \\U0 helper1(U64 x) {
        \\    return x * 2;
        \\}
        \\
        \\U0 helper2(U64 x) {
        \\    return x + 5;
        \\}
        \\
        \\U0 main() {
        \\    U64 val = helper1(10);
        \\    val = helper2(val);
        \\    PrintF("Result: %d\n", val);
        \\    return 0;
        \\}
    ;

    var compiler = Compiler.Compiler.init(testing.allocator, source);
    const bytecode = try compiler.compile();
    defer testing.allocator.free(bytecode);

    try testing.expect(bytecode.len > 0);
}

test "compile with error checking" {
    const source =
        \\U0 safe_divide(U64 a, U64 b) {
        \\    if (b == 0) {
        \\        return 0;
        \\    }
        \\    return a / b;
        \\}
        \\
        \\U0 main() {
        \\    U64 result = safe_divide(10, 2);
        \\    PrintF("Result: %d\n", result);
        \\    result = safe_divide(10, 0);
        \\    PrintF("Safe result: %d\n", result);
        \\    return 0;
        \\}
    ;

    var compiler = Compiler.Compiler.init(testing.allocator, source);
    const bytecode = try compiler.compile();
    defer testing.allocator.free(bytecode);

    try testing.expect(bytecode.len > 0);
}