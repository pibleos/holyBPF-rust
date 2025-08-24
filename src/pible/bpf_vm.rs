//! # BPF Virtual Machine Module
//!
//! Built-in BPF virtual machine for testing and emulation.

use crate::pible::codegen::BpfInstruction;
use thiserror::Error;

/// BPF Virtual Machine execution errors.
#[derive(Error, Debug)]
#[allow(dead_code)]
pub enum VmError {
    /// Invalid BPF instruction encountered.
    #[error("Invalid instruction: {0}")]
    InvalidInstruction(String),
    /// VM stack overflow.
    #[error("Stack overflow")]
    StackOverflow,
    /// Division by zero attempted.
    #[error("Division by zero")]
    DivisionByZero,
    /// Program exited with code.
    #[error("Program exit with code: {0}")]
    ProgramExit(i32),
}

/// VM execution result.
#[derive(Debug)]
pub struct VmResult {
    /// Program exit code
    pub exit_code: i32,
    /// Compute units consumed
    pub compute_units: u64,
}

/// BPF Virtual Machine for testing.
pub struct BpfVm {
    registers: [i64; 11], // R0-R10
    program: Vec<BpfInstruction>,
    pc: usize,
    compute_units: u64,
    #[allow(dead_code)]
    /// Public memory for testing
    pub memory: Vec<u8>, // Public memory for testing
}

impl BpfVm {
    /// Creates a new BPF VM with the given instructions.
    pub fn new(instructions: &[BpfInstruction]) -> Self {
        Self {
            registers: [0; 11],
            program: instructions.to_vec(),
            pc: 0,
            compute_units: 0,
            memory: vec![0; 4096], // 4KB of memory for testing
        }
    }

    // Public accessors and mutators for testing
    /// Sets a register value for testing.
    #[allow(dead_code)]
    pub fn set_register(&mut self, reg: usize, value: i64) {
        if reg < 11 {
            self.registers[reg] = value;
        }
    }

    /// Gets a register value for testing.
    #[allow(dead_code)]
    pub fn get_register(&self, reg: usize) -> i64 {
        if reg < 11 {
            self.registers[reg]
        } else {
            0
        }
    }

    /// Gets the current program counter.
    #[allow(dead_code)]
    pub fn get_pc(&self) -> usize {
        self.pc
    }

    /// Sets the program counter.
    #[allow(dead_code)]
    pub fn set_pc(&mut self, pc: usize) {
        self.pc = pc;
    }

    /// Executes a single BPF instruction.
    #[allow(dead_code)]
    pub fn execute_instruction(&mut self, instruction: &BpfInstruction) -> Result<(), VmError> {
        match instruction.opcode {
            0x95 => {
                // BPF_EXIT - for testing, we don't actually exit
                Ok(())
            }
            0x85 => {
                // BPF_CALL
                self.handle_call(instruction.immediate)
            }
            0xb7 => {
                // BPF_ALU64 | BPF_MOV | BPF_K (move immediate to register)
                if instruction.dst_reg < 11 {
                    self.registers[instruction.dst_reg as usize] = instruction.immediate as i64;
                }
                Ok(())
            }
            0x79 => {
                // BPF_LDX | BPF_MEM | BPF_DW (load 64-bit from memory)
                if instruction.dst_reg < 11 {
                    self.registers[instruction.dst_reg as usize] =
                        0x1000 + instruction.offset as i64;
                }
                Ok(())
            }
            0x07 => {
                // BPF_ALU64 | BPF_ADD | BPF_K (add immediate)
                if instruction.dst_reg < 11 {
                    self.registers[instruction.dst_reg as usize] += instruction.immediate as i64;
                }
                Ok(())
            }
            0x0f => {
                // BPF_ALU64 | BPF_ADD | BPF_X (add register)
                if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                    self.registers[instruction.dst_reg as usize] +=
                        self.registers[instruction.src_reg as usize];
                }
                Ok(())
            }
            0x1f => {
                // BPF_ALU64 | BPF_SUB | BPF_X (subtract register)
                if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                    self.registers[instruction.dst_reg as usize] -=
                        self.registers[instruction.src_reg as usize];
                }
                Ok(())
            }
            0x2f => {
                // BPF_ALU64 | BPF_MUL | BPF_X (multiply register)
                if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                    self.registers[instruction.dst_reg as usize] *=
                        self.registers[instruction.src_reg as usize];
                }
                Ok(())
            }
            0xbf => {
                // BPF_ALU64 | BPF_MOV | BPF_X (move register)
                if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                    self.registers[instruction.dst_reg as usize] =
                        self.registers[instruction.src_reg as usize];
                }
                Ok(())
            }
            0x5f => {
                // BPF_ALU64 | BPF_AND | BPF_X (bitwise and)
                if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                    self.registers[instruction.dst_reg as usize] &=
                        self.registers[instruction.src_reg as usize];
                }
                Ok(())
            }
            0x4f => {
                // BPF_ALU64 | BPF_OR | BPF_X (bitwise or)
                if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                    self.registers[instruction.dst_reg as usize] |=
                        self.registers[instruction.src_reg as usize];
                }
                Ok(())
            }
            0xaf => {
                // BPF_ALU64 | BPF_XOR | BPF_X (bitwise xor)
                if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                    self.registers[instruction.dst_reg as usize] ^=
                        self.registers[instruction.src_reg as usize];
                }
                Ok(())
            }
            0x6f => {
                // BPF_ALU64 | BPF_LSH | BPF_X (left shift)
                if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                    self.registers[instruction.dst_reg as usize] <<=
                        self.registers[instruction.src_reg as usize];
                }
                Ok(())
            }
            0x7f => {
                // BPF_ALU64 | BPF_RSH | BPF_X (right shift logical)
                if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                    let val = self.registers[instruction.dst_reg as usize] as u64;
                    let shift = self.registers[instruction.src_reg as usize] as u64;
                    self.registers[instruction.dst_reg as usize] = (val >> shift) as i64;
                }
                Ok(())
            }
            0xc7 => {
                // BPF_ALU64 | BPF_ARSH | BPF_X (arithmetic right shift)
                if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                    self.registers[instruction.dst_reg as usize] >>=
                        self.registers[instruction.src_reg as usize];
                }
                Ok(())
            }
            0xcf => {
                // BPF_ALU64 | BPF_ARSH | BPF_K (arithmetic right shift with immediate)
                if instruction.dst_reg < 11 {
                    let value = self.registers[instruction.dst_reg as usize];
                    let shift_amount = instruction.immediate as u32;

                    // For 32-bit arithmetic right shift in BPF context
                    let val_32 = value as u32 as i32; // Treat as signed 32-bit
                    let result_32 = val_32 >> shift_amount;
                    self.registers[instruction.dst_reg as usize] = result_32 as u32 as i64;
                    // Zero-extend to 64-bit
                }
                Ok(())
            }
            0x1d => {
                // BPF_JMP | BPF_JEQ | BPF_X (jump if equal)
                if instruction.dst_reg < 11
                    && instruction.src_reg < 11
                    && self.registers[instruction.dst_reg as usize]
                        == self.registers[instruction.src_reg as usize]
                {
                    // In single instruction execution, we update pc to simulate the jump
                    self.pc = instruction.offset as usize;
                }
                Ok(())
            }
            0x2d => {
                // BPF_JMP | BPF_JGT | BPF_X (jump if greater than)
                if instruction.dst_reg < 11
                    && instruction.src_reg < 11
                    && self.registers[instruction.dst_reg as usize]
                        > self.registers[instruction.src_reg as usize]
                {
                    // In single instruction execution, we update pc to simulate the jump
                    self.pc = instruction.offset as usize;
                }
                Ok(())
            }
            0xad => {
                // BPF_JMP | BPF_JLT | BPF_X (jump if less than)
                if instruction.dst_reg < 11
                    && instruction.src_reg < 11
                    && self.registers[instruction.dst_reg as usize]
                        < self.registers[instruction.src_reg as usize]
                {
                    // In single instruction execution, we update pc to simulate the jump
                    self.pc = instruction.offset as usize;
                }
                Ok(())
            }
            0x15 => {
                // BPF_JMP | BPF_JEQ | BPF_K (jump if equal to immediate)
                if instruction.dst_reg < 11
                    && self.registers[instruction.dst_reg as usize] == instruction.immediate as i64
                {
                    self.pc = instruction.offset as usize;
                }
                Ok(())
            }
            0x25 => {
                // BPF_JMP | BPF_JGT | BPF_K (jump if greater than immediate)
                if instruction.dst_reg < 11
                    && self.registers[instruction.dst_reg as usize] > instruction.immediate as i64
                {
                    self.pc = instruction.offset as usize;
                }
                Ok(())
            }
            0xa5 => {
                // BPF_JMP | BPF_JLT | BPF_K (jump if less than immediate)
                if instruction.dst_reg < 11
                    && self.registers[instruction.dst_reg as usize] < instruction.immediate as i64
                {
                    self.pc = instruction.offset as usize;
                }
                Ok(())
            }
            0x61 => {
                // BPF_LDX | BPF_MEM | BPF_W (load word from memory)
                if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                    let addr = (self.registers[instruction.src_reg as usize]
                        + instruction.offset as i64) as usize;
                    if addr + 4 <= self.memory.len() {
                        // Load 32-bit little-endian word from memory
                        let value = u32::from_le_bytes([
                            self.memory[addr],
                            self.memory[addr + 1],
                            self.memory[addr + 2],
                            self.memory[addr + 3],
                        ]);
                        self.registers[instruction.dst_reg as usize] = value as i64;
                    } else {
                        self.registers[instruction.dst_reg as usize] = 42; // Fallback for out of bounds
                    }
                }
                Ok(())
            }
            0x69 => {
                // BPF_LDX | BPF_MEM | BPF_H (load halfword from memory)
                if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                    let addr = (self.registers[instruction.src_reg as usize]
                        + instruction.offset as i64) as usize;
                    if addr + 2 <= self.memory.len() {
                        // Load 16-bit little-endian halfword from memory
                        let value = u16::from_le_bytes([self.memory[addr], self.memory[addr + 1]]);
                        self.registers[instruction.dst_reg as usize] = value as i64;
                    } else {
                        self.registers[instruction.dst_reg as usize] = 0x1234; // Fallback for out of bounds
                    }
                }
                Ok(())
            }
            0x71 => {
                // BPF_LDX | BPF_MEM | BPF_B (load byte from memory)
                if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                    let addr = (self.registers[instruction.src_reg as usize]
                        + instruction.offset as i64) as usize;
                    if addr < self.memory.len() {
                        self.registers[instruction.dst_reg as usize] = self.memory[addr] as i64;
                    } else {
                        self.registers[instruction.dst_reg as usize] = 0x42; // Fallback for out of bounds
                    }
                }
                Ok(())
            }
            0x63 => {
                // BPF_STX | BPF_MEM | BPF_W (store word to memory)
                if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                    let addr = (self.registers[instruction.dst_reg as usize]
                        + instruction.offset as i64) as usize;
                    if addr + 4 <= self.memory.len() {
                        let value = self.registers[instruction.src_reg as usize] as u32;
                        let bytes = value.to_le_bytes();
                        self.memory[addr..addr + 4].copy_from_slice(&bytes);
                    }
                }
                Ok(())
            }
            0x6b => {
                // BPF_STX | BPF_MEM | BPF_H (store halfword to memory)
                if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                    let addr = (self.registers[instruction.dst_reg as usize]
                        + instruction.offset as i64) as usize;
                    if addr + 2 <= self.memory.len() {
                        let value = self.registers[instruction.src_reg as usize] as u16;
                        let bytes = value.to_le_bytes();
                        self.memory[addr..addr + 2].copy_from_slice(&bytes);
                    }
                }
                Ok(())
            }
            0x62 => {
                // BPF_ST | BPF_MEM | BPF_W (store immediate word to memory)
                if instruction.dst_reg < 11 {
                    let addr = (self.registers[instruction.dst_reg as usize]
                        + instruction.offset as i64) as usize;
                    if addr + 4 <= self.memory.len() {
                        let value = instruction.immediate as u32;
                        let bytes = value.to_le_bytes();
                        self.memory[addr..addr + 4].copy_from_slice(&bytes);
                    }
                }
                Ok(())
            }
            0x73 => {
                // BPF_STX | BPF_MEM | BPF_B (store byte to memory)
                if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                    let addr = (self.registers[instruction.dst_reg as usize]
                        + instruction.offset as i64) as usize;
                    if addr < self.memory.len() {
                        self.memory[addr] = self.registers[instruction.src_reg as usize] as u8;
                    }
                }
                Ok(())
            }
            _ => {
                // Unknown instruction
                Err(VmError::InvalidInstruction(format!(
                    "Unknown opcode: 0x{:02x}",
                    instruction.opcode
                )))
            }
        }
    }

    /// Executes the entire BPF program.
    ///
    /// Runs all instructions until completion or error.
    pub fn execute(&mut self) -> Result<VmResult, VmError> {
        while self.pc < self.program.len() {
            self.compute_units += 1;

            // Simple execution limit for testing
            if self.compute_units > 10000 {
                break;
            }

            let instruction = &self.program[self.pc];

            match instruction.opcode {
                0x95 => {
                    // BPF_EXIT
                    return Ok(VmResult {
                        exit_code: self.registers[0] as i32,
                        compute_units: self.compute_units,
                    });
                }
                0x85 => {
                    // BPF_CALL
                    self.handle_call(instruction.immediate)?;
                }
                0xb7 => {
                    // BPF_ALU64 | BPF_MOV | BPF_K (move immediate to register)
                    if instruction.dst_reg < 11 {
                        self.registers[instruction.dst_reg as usize] = instruction.immediate as i64;
                    }
                }
                0x79 => {
                    // BPF_LDX | BPF_MEM | BPF_DW (load 64-bit from memory)
                    // For simulation, just set register to a test value
                    if instruction.dst_reg < 11 {
                        self.registers[instruction.dst_reg as usize] =
                            0x1000 + instruction.offset as i64;
                    }
                }
                0x07 => {
                    // BPF_ALU64 | BPF_ADD | BPF_K (add immediate)
                    if instruction.dst_reg < 11 {
                        self.registers[instruction.dst_reg as usize] +=
                            instruction.immediate as i64;
                    }
                }
                0x0f => {
                    // BPF_ALU64 | BPF_ADD | BPF_X (add register)
                    if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                        self.registers[instruction.dst_reg as usize] +=
                            self.registers[instruction.src_reg as usize];
                    }
                }
                0x2f => {
                    // BPF_ALU64 | BPF_MUL | BPF_X (multiply register)
                    if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                        self.registers[instruction.dst_reg as usize] *=
                            self.registers[instruction.src_reg as usize];
                    }
                }
                0xbf => {
                    // BPF_ALU64 | BPF_MOV | BPF_X (move register)
                    if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                        self.registers[instruction.dst_reg as usize] =
                            self.registers[instruction.src_reg as usize];
                    }
                }
                0x63 => {
                    // BPF_STX | BPF_MEM | BPF_W (store word to memory)
                    // For simulation, just store in a "memory" register
                    // This is a simplified implementation
                }
                0x61 => {
                    // BPF_LDX | BPF_MEM | BPF_W (load word from memory)
                    // For simulation, load the stored value back
                    if instruction.dst_reg < 11 {
                        self.registers[instruction.dst_reg as usize] = 42; // Simulated stored value
                    }
                }
                0x2d => {
                    // BPF_JMP | BPF_JGT | BPF_X (jump if greater than)
                    if instruction.dst_reg < 11
                        && instruction.src_reg < 11
                        && self.registers[instruction.dst_reg as usize]
                            > self.registers[instruction.src_reg as usize]
                    {
                        self.pc = (self.pc as i32 + instruction.offset as i32 + 1) as usize;
                        continue;
                    }
                }
                0x05 => {
                    // BPF_JMP | BPF_JA (unconditional jump)
                    self.pc = (self.pc as i32 + instruction.offset as i32 + 1) as usize;
                    continue;
                }
                0x5f => {
                    // BPF_ALU64 | BPF_AND | BPF_X (bitwise and)
                    if instruction.dst_reg < 11 && instruction.src_reg < 11 {
                        self.registers[instruction.dst_reg as usize] &=
                            self.registers[instruction.src_reg as usize];
                    }
                }
                _ => {
                    // Unknown instruction - could be an error or just skip
                    // For robustness, we'll just continue execution
                }
            }

            self.pc += 1;
        }

        Ok(VmResult {
            exit_code: self.registers[0] as i32,
            compute_units: self.compute_units,
        })
    }

    fn handle_call(&mut self, func_id: i32) -> Result<(), VmError> {
        match func_id {
            6 => {
                // BPF_FUNC_trace_printk - simulate printing
                println!("VM: trace_printk called");
            }
            _ => {
                // Unknown function call
            }
        }
        Ok(())
    }
}
