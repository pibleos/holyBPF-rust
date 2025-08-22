// BPF Virtual Machine Emulator
// This module provides a BPF VM emulator for testing and debugging BPF programs

const std = @import("std");
const CodeGen = @import("CodeGen.zig");
const SolanaBpf = @import("SolanaBpf.zig");
const BpfInstruction = CodeGen.BpfInstruction;

// BPF VM Execution errors
pub const BpfVmError = error{
    InvalidInstruction,
    InvalidRegister,
    StackOverflow,
    StackUnderflow,
    DivisionByZero,
    InvalidMemoryAccess,
    ProgramCounterOutOfBounds,
    ComputeUnitsExceeded,
    InvalidSystemCall,
    ProgramExit,
};

// BPF VM execution result
pub const BpfVmResult = struct {
    exit_code: u64,
    compute_units_used: u64,
    logs: std.ArrayList([]const u8),
    return_data: ?[]const u8,
};

// BPF Virtual Machine state
pub const BpfVm = struct {
    // BPF has 11 64-bit registers (r0-r10)
    registers: [11]u64,
    
    // Program counter
    pc: usize,
    
    // Program memory
    program: []const BpfInstruction,
    
    // Stack memory (512 bytes)
    stack: [512]u8,
    stack_ptr: usize,
    
    // Heap memory for dynamic allocation
    heap: std.ArrayList(u8),
    
    // Execution statistics
    compute_units: u64,
    max_compute_units: u64,
    
    // VM configuration
    allocator: std.mem.Allocator,
    logs: std.ArrayList([]const u8),
    return_data: ?[]const u8,
    
    // Solana-specific state
    solana_accounts: ?[]SolanaBpf.SolanaAccount,
    program_id: ?[32]u8,
    
    const Self = @This();
    
    pub fn init(allocator: std.mem.Allocator, program: []const BpfInstruction) Self {
        return .{
            .registers = [_]u64{0} ** 11,
            .pc = 0,
            .program = program,
            .stack = [_]u8{0} ** 512,
            .stack_ptr = 512, // Stack grows downward
            .heap = std.ArrayList(u8).init(allocator),
            .compute_units = 0,
            .max_compute_units = 200_000, // Solana BPF limit
            .allocator = allocator,
            .logs = std.ArrayList([]const u8).init(allocator),
            .return_data = null,
            .solana_accounts = null,
            .program_id = null,
        };
    }
    
    pub fn deinit(self: *Self) void {
        self.heap.deinit();
        for (self.logs.items) |log| {
            self.allocator.free(log);
        }
        self.logs.deinit();
        if (self.return_data) |data| {
            self.allocator.free(data);
        }
    }
    
    /// Execute the BPF program
    pub fn execute(self: *Self) !BpfVmResult {
        // Initialize r10 to point to stack frame
        self.registers[10] = @intFromPtr(&self.stack) + self.stack.len;
        
        while (self.pc < self.program.len) {
            if (self.compute_units >= self.max_compute_units) {
                return BpfVmError.ComputeUnitsExceeded;
            }
            
            const instruction = self.program[self.pc];
            try self.executeInstruction(instruction);
            
            self.compute_units += 1;
            self.pc += 1;
        }
        
        return BpfVmResult{
            .exit_code = self.registers[0],
            .compute_units_used = self.compute_units,
            .logs = self.logs,
            .return_data = self.return_data,
        };
    }
    
    /// Execute a single BPF instruction
    fn executeInstruction(self: *Self, instruction: BpfInstruction) !void {
        const opcode = instruction.opcode;
        const dst = instruction.dst_reg;
        const src = instruction.src_reg;
        const offset = instruction.offset;
        const imm = instruction.imm;
        
        // Validate register indices
        if (dst > 10 or src > 10) {
            return BpfVmError.InvalidRegister;
        }
        
        switch (opcode) {
            // ALU64 operations
            0x07 => { // BPF_ALU64 | BPF_ADD | BPF_X
                self.registers[dst] = self.registers[dst] +% self.registers[src];
            },
            0x17 => { // BPF_ALU64 | BPF_ADD | BPF_K
                self.registers[dst] = self.registers[dst] +% @as(u64, @bitCast(@as(i64, imm)));
            },
            0x1f => { // BPF_ALU64 | BPF_SUB | BPF_X
                self.registers[dst] = self.registers[dst] -% self.registers[src];
            },
            0x2f => { // BPF_ALU64 | BPF_MUL | BPF_X
                self.registers[dst] = self.registers[dst] *% self.registers[src];
            },
            0x3f => { // BPF_ALU64 | BPF_DIV | BPF_X
                if (self.registers[src] == 0) {
                    return BpfVmError.DivisionByZero;
                }
                self.registers[dst] = self.registers[dst] / self.registers[src];
            },
            
            // MOV operations
            0xbf => { // BPF_ALU64 | BPF_MOV | BPF_X
                self.registers[dst] = self.registers[src];
            },
            0xb7 => { // BPF_ALU64 | BPF_MOV | BPF_K
                self.registers[dst] = @as(u64, @bitCast(@as(i64, imm)));
            },
            
            // Load/Store operations
            0x79 => { // BPF_LDX | BPF_MEM | BPF_DW (64-bit load)
                const addr = self.registers[src] +% @as(u64, @bitCast(@as(i64, offset)));
                self.registers[dst] = try self.readMemory64(addr);
            },
            0x7b => { // BPF_STX | BPF_MEM | BPF_DW (64-bit store)
                const addr = self.registers[dst] +% @as(u64, @bitCast(@as(i64, offset)));
                try self.writeMemory64(addr, self.registers[src]);
            },
            
            // Jump operations
            0x05 => { // BPF_JMP | BPF_JA
                self.pc = @as(usize, @intCast(@as(i32, @intCast(self.pc)) + offset));
                return; // Don't increment PC again
            },
            0x15 => { // BPF_JMP | BPF_JEQ | BPF_K
                if (self.registers[dst] == @as(u64, @bitCast(@as(i64, imm)))) {
                    self.pc = @as(usize, @intCast(@as(i32, @intCast(self.pc)) + offset));
                    return; // Don't increment PC again
                }
            },
            0x1d => { // BPF_JMP | BPF_JEQ | BPF_X
                if (self.registers[dst] == self.registers[src]) {
                    self.pc = @as(usize, @intCast(@as(i32, @intCast(self.pc)) + offset));
                    return; // Don't increment PC again
                }
            },
            
            // Function calls
            0x85 => { // BPF_JMP | BPF_CALL
                try self.executeSystemCall(@as(u32, @intCast(imm)));
            },
            
            // Exit
            0x95 => { // BPF_JMP | BPF_EXIT
                return BpfVmError.ProgramExit;
            },
            
            else => {
                std.debug.print("Unknown opcode: 0x{x}\n", .{opcode});
                return BpfVmError.InvalidInstruction;
            },
        }
    }
    
    /// Execute a BPF system call
    fn executeSystemCall(self: *Self, syscall_id: u32) !void {
        switch (syscall_id) {
            // Linux BPF system calls
            6 => { // bpf_trace_printk
                try self.handleTracePrintk();
            },
            
            // Solana BPF system calls
            1 => { // sol_log
                try self.handleSolanaLog();
            },
            2 => { // sol_log_64
                try self.handleSolanaLog64();
            },
            4 => { // sol_log_pubkey
                try self.handleSolanaLogPubkey();
            },
            
            else => {
                std.debug.print("Unknown syscall: {}\n", .{syscall_id});
                return BpfVmError.InvalidSystemCall;
            },
        }
    }
    
    /// Handle Linux BPF trace_printk system call
    fn handleTracePrintk(self: *Self) !void {
        // r1 contains format string pointer
        // r2-r5 contain arguments
        const fmt_ptr = self.registers[1];
        
        // For now, just log the fact that printk was called
        const log_msg = try std.fmt.allocPrint(self.allocator, "BPF trace_printk called with format at 0x{x}", .{fmt_ptr});
        try self.logs.append(log_msg);
        
        // Return number of bytes written
        self.registers[0] = 20; // Fake return value
    }
    
    /// Handle Solana sol_log system call
    fn handleSolanaLog(self: *Self) !void {
        // r1 contains pointer to message string
        // r2 contains message length
        const msg_ptr = self.registers[1];
        const msg_len = self.registers[2];
        
        // For emulation, create a log entry
        const log_msg = try std.fmt.allocPrint(self.allocator, "SOL_LOG: message at 0x{x}, length {}", .{ msg_ptr, msg_len });
        try self.logs.append(log_msg);
        
        self.registers[0] = 0; // Success
    }
    
    /// Handle Solana sol_log_64 system call
    fn handleSolanaLog64(self: *Self) !void {
        // r1-r5 contain 64-bit values to log
        const values = [_]u64{ self.registers[1], self.registers[2], self.registers[3], self.registers[4], self.registers[5] };
        
        var log_buffer = std.ArrayList(u8).init(self.allocator);
        defer log_buffer.deinit();
        
        try log_buffer.appendSlice("SOL_LOG_64: ");
        for (values, 0..) |value, i| {
            if (i > 0) try log_buffer.appendSlice(", ");
            try std.fmt.format(log_buffer.writer(), "{}", .{value});
        }
        
        const log_msg = try log_buffer.toOwnedSlice();
        try self.logs.append(log_msg);
        
        self.registers[0] = 0; // Success
    }
    
    /// Handle Solana sol_log_pubkey system call
    fn handleSolanaLogPubkey(self: *Self) !void {
        // r1 contains pointer to public key (32 bytes)
        const pubkey_ptr = self.registers[1];
        
        const log_msg = try std.fmt.allocPrint(self.allocator, "SOL_LOG_PUBKEY: pubkey at 0x{x}", .{pubkey_ptr});
        try self.logs.append(log_msg);
        
        self.registers[0] = 0; // Success
    }
    
    /// Read 64-bit value from memory
    fn readMemory64(self: *Self, addr: u64) !u64 {
        // Check if address is in stack range
        const stack_start = @intFromPtr(&self.stack);
        const stack_end = stack_start + self.stack.len;
        
        if (addr >= stack_start and addr + 8 <= stack_end) {
            const offset = addr - stack_start;
            return std.mem.readInt(u64, self.stack[offset..][0..8], std.builtin.Endian.little);
        }
        
        // Check if address is in heap range
        if (self.heap.items.len > 0) {
            const heap_start = @intFromPtr(self.heap.items.ptr);
            const heap_end = heap_start + self.heap.items.len;
            
            if (addr >= heap_start and addr + 8 <= heap_end) {
                const offset = addr - heap_start;
                return std.mem.readInt(u64, self.heap.items[offset..][0..8], std.builtin.Endian.little);
            }
        }
        
        return BpfVmError.InvalidMemoryAccess;
    }
    
    /// Write 64-bit value to memory
    fn writeMemory64(self: *Self, addr: u64, value: u64) !void {
        // Check if address is in stack range
        const stack_start = @intFromPtr(&self.stack);
        const stack_end = stack_start + self.stack.len;
        
        if (addr >= stack_start and addr + 8 <= stack_end) {
            const offset = addr - stack_start;
            std.mem.writeInt(u64, self.stack[offset..][0..8], value, std.builtin.Endian.little);
            return;
        }
        
        // Check if address is in heap range
        if (self.heap.items.len > 0) {
            const heap_start = @intFromPtr(self.heap.items.ptr);
            const heap_end = heap_start + self.heap.items.len;
            
            if (addr >= heap_start and addr + 8 <= heap_end) {
                const offset = addr - heap_start;
                std.mem.writeInt(u64, self.heap.items[offset..][0..8], value, std.builtin.Endian.little);
                return;
            }
        }
        
        return BpfVmError.InvalidMemoryAccess;
    }
    
    /// Set up Solana program execution environment
    pub fn setupSolanaEnvironment(self: *Self, accounts: []SolanaBpf.SolanaAccount, program_id: [32]u8, instruction_data: []const u8) !void {
        self.solana_accounts = accounts;
        self.program_id = program_id;
        
        // Set up Solana calling convention
        // r1 points to input buffer containing serialized accounts and instruction data
        self.registers[1] = @intFromPtr(instruction_data.ptr);
    }
    
    /// Get execution statistics
    pub fn getStats(self: *Self) struct { compute_units: u64, log_count: usize } {
        return .{
            .compute_units = self.compute_units,
            .log_count = self.logs.items.len,
        };
    }
    
    /// Reset VM state for new execution
    pub fn reset(self: *Self) void {
        self.registers = [_]u64{0} ** 11;
        self.pc = 0;
        self.stack = [_]u8{0} ** 512;
        self.stack_ptr = 512;
        self.compute_units = 0;
        
        // Clear logs
        for (self.logs.items) |log| {
            self.allocator.free(log);
        }
        self.logs.clearRetainingCapacity();
        
        if (self.return_data) |data| {
            self.allocator.free(data);
            self.return_data = null;
        }
    }
};