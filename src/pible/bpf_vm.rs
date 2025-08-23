use crate::pible::codegen::BpfInstruction;
use thiserror::Error;

#[derive(Error, Debug)]
#[allow(dead_code)]
pub enum VmError {
    #[error("Invalid instruction: {0}")]
    InvalidInstruction(String),
    #[error("Stack overflow")]
    StackOverflow,
    #[error("Division by zero")]
    DivisionByZero,
    #[error("Program exit with code: {0}")]
    ProgramExit(i32),
}

#[derive(Debug)]
pub struct VmResult {
    pub exit_code: i32,
    pub compute_units: u64,
}

pub struct BpfVm {
    registers: [i64; 11], // R0-R10
    program: Vec<BpfInstruction>,
    pc: usize,
    compute_units: u64,
}

impl BpfVm {
    pub fn new(instructions: &[BpfInstruction]) -> Self {
        Self {
            registers: [0; 11],
            program: instructions.to_vec(),
            pc: 0,
            compute_units: 0,
        }
    }

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
