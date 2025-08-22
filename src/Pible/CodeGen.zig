const std = @import("std");
const parser = @import("Parser.zig");
const Node = parser.Node;
const NodeType = parser.NodeType;

pub const CodeGenError = error{
    OutOfMemory,
    UnsupportedBinaryOp,
    UnsupportedComparison,
    UnsupportedUnaryOp,
    UnsupportedFunctionCall,
    UndefinedVariable,
    RegisterSpillover,
    InvalidInstruction,
};

// BPF instruction structure (64-bit BPF instruction format)
pub const BpfInstruction = packed struct {
    opcode: u8,      // Operation code
    dst_reg: u4,     // Destination register (0-15)
    src_reg: u4,     // Source register (0-15)  
    offset: i16,     // Signed offset (used in jumps and memory operations)
    imm: i32,        // Immediate value (32-bit signed)
    
    /// Verify instruction is valid BPF format
    pub fn validate(self: BpfInstruction) bool {
        // Basic validation - registers should be 0-10 for BPF
        return self.dst_reg <= 10 and self.src_reg <= 10;
    }
};

// BPF opcodes
const BPF_JMP = 0x05;
const BPF_ALU64 = 0x07;
const BPF_ALU = 0x04;
const BPF_LD = 0x00;
const BPF_LDX = 0x01;
const BPF_ST = 0x02;
const BPF_STX = 0x03;

// ALU operations
const BPF_ADD = 0x00;
const BPF_SUB = 0x10;
const BPF_MUL = 0x20;
const BPF_DIV = 0x30;
const BPF_MOV = 0xb0;

// Jump operations
const BPF_EXIT = 0x90;
const BPF_CALL = 0x80;

pub const CodeGen = struct {
    instructions: std.ArrayList(BpfInstruction),
    current_function: ?[]const u8,
    stack_size: usize,
    allocator: std.mem.Allocator,
    labels: std.HashMap([]const u8, usize, std.hash_map.StringContext, std.hash_map.default_max_load_percentage),
    variables: std.HashMap([]const u8, i16, std.hash_map.StringContext, std.hash_map.default_max_load_percentage),
    local_offset: i16,
    
    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .instructions = std.ArrayList(BpfInstruction).init(allocator),
            .current_function = null,
            .stack_size = 0,
            .allocator = allocator,
            .labels = std.HashMap([]const u8, usize, std.hash_map.StringContext, std.hash_map.default_max_load_percentage).init(allocator),
            .variables = std.HashMap([]const u8, i16, std.hash_map.StringContext, std.hash_map.default_max_load_percentage).init(allocator),
            .local_offset = 0,
        };
    }

    pub fn deinit(self: *Self) void {
        self.instructions.deinit();
        self.labels.deinit();
        self.variables.deinit();
    }

    /// Generate BPF bytecode from AST
    pub fn generate(self: *Self, ast: *Node) CodeGenError!void {
        try self.generateNode(ast);
        // Ensure program ends with exit instruction
        if (self.instructions.items.len == 0 or 
            self.instructions.items[self.instructions.items.len - 1].opcode != (BPF_JMP | BPF_EXIT)) {
            try self.emitExit();
        }
    }

    /// Generate code for a specific AST node
    fn generateNode(self: *Self, node: *Node) CodeGenError!void {
        switch (node.type) {
            .Program => {
                for (node.children.items) |child| {
                    try self.generateNode(child);
                }
            },
            .FunctionDecl => {
                self.current_function = node.token.lexeme;
                self.local_offset = 0;
                self.variables.clearRetainingCapacity();
                
                // Generate function body
                for (node.children.items) |child| {
                    try self.generateNode(child);
                }
            },
            .Block => {
                for (node.children.items) |child| {
                    try self.generateNode(child);
                }
            },
            .VarDecl => {
                // Allocate space on stack
                self.local_offset -= 8; // 8 bytes for U64
                try self.variables.put(node.token.lexeme, self.local_offset);
                
                // If there's an initializer, generate it and store
                if (node.children.items.len > 0) {
                    try self.generateNode(node.children.items[0]);
                    try self.emitStore(self.local_offset);
                }
            },
            .ReturnStmt => {
                if (node.children.items.len > 0) {
                    try self.generateNode(node.children.items[0]);
                } else {
                    try self.emitMov(0, 0); // Return 0
                }
                try self.emitExit();
            },
            .ExprStmt => {
                try self.generateNode(node.children.items[0]);
            },
            .BinaryExpr => {
                try self.generateBinaryExpr(node);
            },
            .UnaryExpr => {
                try self.generateUnaryExpr(node);
            },
            .CallExpr => {
                try self.generateCallExpr(node);
            },
            .Literal => {
                try self.generateLiteral(node);
            },
            .Identifier => {
                try self.generateIdentifier(node);
            },
            .IfStmt => {
                try self.generateIfStmt(node);
            },
            .WhileStmt => {
                try self.generateWhileStmt(node);
            },
        }
    }

    fn generateBinaryExpr(self: *Self, node: *Node) CodeGenError!void {
        // Generate left operand
        try self.generateNode(node.children.items[0]);
        try self.emitMov(1, 0); // Move result to r1
        
        // Generate right operand  
        try self.generateNode(node.children.items[1]);
        // Result is in r0, left operand is in r1
        
        switch (node.token.type) {
            .Plus => try self.emitAlu64(BPF_ADD, 0, 1),
            .Minus => {
                // For subtraction: r0 = r1 - r0 (left - right)
                try self.emitMov(2, 0); // Save right operand in r2
                try self.emitMov(0, 1); // Move left to r0
                try self.emitAlu64(BPF_SUB, 0, 2); // r0 = r0 - r2
            },
            .Star => try self.emitAlu64(BPF_MUL, 0, 1),
            .Slash => {
                // Division: r0 = r1 / r0 (left / right)
                try self.emitMov(2, 0); // Save right operand in r2
                try self.emitMov(0, 1); // Move left to r0
                try self.emitAlu64(BPF_DIV, 0, 2); // r0 = r0 / r2
            },
            .Percent => {
                // Modulo operation
                try self.emitMov(2, 0);
                try self.emitMov(0, 1);
                try self.emitAlu64(0x90, 0, 2); // BPF_MOD
            },
            .EqualEqual, .BangEqual, .Less, .LessEqual, .Greater, .GreaterEqual => {
                // Comparison operations - result is 0 or 1
                try self.generateComparison(node.token.type, 1, 0);
            },
            else => return error.UnsupportedBinaryOp,
        }
    }

    /// Generate comparison operation
    fn generateComparison(self: *Self, op: parser.TokenType, left_reg: u4, right_reg: u4) CodeGenError!void {
        // Set r0 to 1 (true)
        try self.emitMov(0, 1);
        
        // Jump forward if condition is true, otherwise set r0 to 0
        
        switch (op) {
            .EqualEqual => try self.emitJumpCond(0x10, left_reg, right_reg, 2), // JEQ
            .BangEqual => try self.emitJumpCond(0x50, left_reg, right_reg, 2),  // JNE 
            .Less => try self.emitJumpCond(0x20, left_reg, right_reg, 2),       // JLT
            .LessEqual => try self.emitJumpCond(0x30, left_reg, right_reg, 2),  // JLE
            .Greater => try self.emitJumpCond(0x20, right_reg, left_reg, 2),    // JLT reversed
            .GreaterEqual => try self.emitJumpCond(0x30, right_reg, left_reg, 2), // JLE reversed
            else => return error.UnsupportedComparison,
        }
        
        // If condition is false, set r0 to 0
        try self.emitMov(0, 0);
    }

    fn generateUnaryExpr(self: *Self, node: *Node) CodeGenError!void {
        try self.generateNode(node.children.items[0]);
        
        switch (node.token.type) {
            .Minus => {
                // Negate: 0 - value
                try self.emitMov(1, 0); // Move value to r1
                try self.emitMov(0, 0); // Set r0 to 0
                try self.emitAlu64(BPF_SUB, 0, 1); // r0 = r0 - r1
            },
            else => return error.UnsupportedUnaryOp,
        }
    }

    fn generateCallExpr(self: *Self, node: *Node) CodeGenError!void {
        const callee = node.children.items[0];
        
        if (std.mem.eql(u8, callee.token.lexeme, "PrintF")) {
            // Generate arguments in reverse order for BPF calling convention
            var arg_count: u32 = 0;
            for (node.children.items[1..]) |arg| {
                try self.generateNode(arg);
                // Store argument in appropriate register (r1, r2, r3, r4, r5)
                if (arg_count < 5) {
                    try self.emitMov(@intCast(arg_count + 1), 0);
                }
                arg_count += 1;
            }
            
            // Call BPF helper function for trace_printk
            try self.emitCall(6); // BPF_FUNC_trace_printk
        } else {
            // User-defined function call - TODO: implement function table
            return error.UnsupportedFunctionCall;
        }
    }

    fn generateLiteral(self: *Self, node: *Node) CodeGenError!void {
        switch (node.token.type) {
            .NumberLiteral => {
                const value = std.fmt.parseInt(i32, node.token.lexeme, 10) catch 0;
                try self.emitMov(0, value);
            },
            .StringLiteral => {
                // For now, just load string address (simplified)
                try self.emitMov(0, 0);
            },
            else => {},
        }
    }

    fn generateIdentifier(self: *Self, node: *Node) CodeGenError!void {
        const name = node.token.lexeme;
        if (self.variables.get(name)) |offset| {
            try self.emitLoad(offset);
        } else {
            return error.UndefinedVariable;
        }
    }

    fn generateIfStmt(self: *Self, node: *Node) CodeGenError!void {
        // Generate condition
        try self.generateNode(node.children.items[0]);
        
        // Jump if false (simplified)
        const jump_if_false = self.instructions.items.len;
        try self.emitJumpIf(0, 0); // Placeholder
        
        // Generate then branch
        try self.generateNode(node.children.items[1]);
        
        // Patch jump address
        self.instructions.items[jump_if_false].offset = @intCast(self.instructions.items.len - jump_if_false - 1);
        
        // Generate else branch if present
        if (node.children.items.len > 2) {
            try self.generateNode(node.children.items[2]);
        }
    }

    fn generateWhileStmt(self: *Self, node: *Node) CodeGenError!void {
        const loop_start = self.instructions.items.len;
        
        // Generate condition
        try self.generateNode(node.children.items[0]);
        
        // Jump if false to end
        const jump_if_false = self.instructions.items.len;
        try self.emitJumpIf(0, 0); // Placeholder
        
        // Generate body
        try self.generateNode(node.children.items[1]);
        
        // Jump back to condition
        const back_jump_offset = @as(i16, @intCast(loop_start)) - @as(i16, @intCast(self.instructions.items.len)) - 1;
        try self.emitJump(back_jump_offset);
        
        // Patch jump-if-false address
        self.instructions.items[jump_if_false].offset = @intCast(self.instructions.items.len - jump_if_false - 1);
    }

    // BPF instruction emission helpers
    fn emitMov(self: *Self, dst_reg: u4, imm: i32) CodeGenError!void {
        try self.instructions.append( BpfInstruction{
            .opcode = BPF_ALU64 | BPF_MOV,
            .dst_reg = dst_reg,
            .src_reg = 0,
            .offset = 0,
            .imm = imm,
        });
    }

    fn emitAlu64(self: *Self, op: u8, dst_reg: u4, src_reg: u4) CodeGenError!void {
        try self.instructions.append( BpfInstruction{
            .opcode = BPF_ALU64 | op,
            .dst_reg = dst_reg,
            .src_reg = src_reg,
            .offset = 0,
            .imm = 0,
        });
    }

    fn emitLoad(self: *Self, offset: i16) CodeGenError!void {
        try self.instructions.append( BpfInstruction{
            .opcode = BPF_LDX | 0x08, // LDXDW
            .dst_reg = 0,
            .src_reg = 10, // Frame pointer
            .offset = offset,
            .imm = 0,
        });
    }

    fn emitStore(self: *Self, offset: i16) CodeGenError!void {
        try self.instructions.append( BpfInstruction{
            .opcode = BPF_STX | 0x08, // STXDW
            .dst_reg = 10, // Frame pointer
            .src_reg = 0,
            .offset = offset,
            .imm = 0,
        });
    }

    fn emitCall(self: *Self, func_id: i32) CodeGenError!void {
        try self.instructions.append( BpfInstruction{
            .opcode = BPF_JMP | BPF_CALL,
            .dst_reg = 0,
            .src_reg = 0,
            .offset = 0,
            .imm = func_id,
        });
    }

    fn emitJump(self: *Self, offset: i16) CodeGenError!void {
        try self.instructions.append( BpfInstruction{
            .opcode = BPF_JMP | 0x00, // JA
            .dst_reg = 0,
            .src_reg = 0,
            .offset = offset,
            .imm = 0,
        });
    }

    fn emitJumpIf(self: *Self, dst_reg: u4, offset: i16) CodeGenError!void {
        try self.instructions.append( BpfInstruction{
            .opcode = BPF_JMP | 0x10, // JEQ
            .dst_reg = dst_reg,
            .src_reg = 0,
            .offset = offset,
            .imm = 0,
        });
    }

    /// Emit conditional jump instruction
    fn emitJumpCond(self: *Self, condition: u8, dst_reg: u4, src_reg: u4, offset: i16) CodeGenError!void {
        try self.instructions.append( BpfInstruction{
            .opcode = BPF_JMP | condition,
            .dst_reg = dst_reg,
            .src_reg = src_reg,
            .offset = offset,
            .imm = 0,
        });
    }

    fn emitExit(self: *Self) CodeGenError!void {
        try self.instructions.append( BpfInstruction{
            .opcode = BPF_JMP | BPF_EXIT,
            .dst_reg = 0,
            .src_reg = 0,
            .offset = 0,
            .imm = 0,
        });
    }

    /// Get the size of generated bytecode in bytes
    pub fn getBytecodeSize(self: *Self) usize {
        return self.instructions.items.len * @sizeOf(BpfInstruction);
    }

    /// Validate all generated instructions
    pub fn validateInstructions(self: *Self) bool {
        for (self.instructions.items) |instr| {
            if (!instr.validate()) return false;
        }
        return true;
    }
};