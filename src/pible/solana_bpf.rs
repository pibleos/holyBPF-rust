use thiserror::Error;
use crate::pible::codegen::{CodeGen, BpfInstruction};

#[derive(Error, Debug)]
pub enum SolanaError {
    #[error("IDL generation failed: {0}")]
    IdlGenerationFailed(String),
    #[error("Invalid Solana program: {0}")]
    InvalidProgram(String),
}

pub struct SolanaBpf {
    codegen: Vec<BpfInstruction>,
}

impl SolanaBpf {
    pub fn new(_codegen: &mut CodeGen) -> Self {
        Self {
            codegen: Vec::new(),
        }
    }

    pub fn generate_entrypoint(&mut self, name: &str) -> Result<(), SolanaError> {
        // Generate real Solana BPF program entrypoint
        // 1. Load program accounts from instruction data
        // R1 = program_id pointer, R2 = accounts pointer, R3 = instruction_data pointer
        
        // Load accounts array pointer to R6
        self.emit_load_reg(6, 2, 0);  // r6 = accounts
        
        // Load instruction data pointer to R7
        self.emit_load_reg(7, 3, 0);  // r7 = instruction_data
        
        // Set up stack frame for program execution
        self.emit_move_immediate(10, 512);  // r10 = stack_ptr (512 bytes)
        
        // Call the main program logic
        self.emit_call_function(name)?;
        
        // Return success (0) on R0
        self.emit_move_immediate(0, 0);
        self.emit_exit();
        
        Ok(())
    }

    pub fn validate_solana_program(&self, instructions: &[BpfInstruction]) -> bool {
        // Real Solana BPF validation
        if instructions.is_empty() {
            return false;
        }
        
        // Check for required exit instruction
        let has_exit = instructions.iter().any(|inst| inst.opcode & 0xf7 == 0x95);
        if !has_exit {
            return false;
        }
        
        // Validate instruction sequence
        for (i, instruction) in instructions.iter().enumerate() {
            // Check for invalid opcodes
            let class = instruction.opcode & 0x07;
            match class {
                0x00 | 0x01 | 0x02 | 0x03 | 0x04 | 0x05 | 0x07 => {
                    // Valid instruction classes (LD, LDX, ST, STX, ALU, JMP, ALU64)
                },
                _ => return false,
            }
            
            // Check register bounds (0-10 for BPF)
            if instruction.dst_reg > 10 || instruction.src_reg > 10 {
                return false;
            }
            
            // Validate jump targets
            if (instruction.opcode & 0xf0) == 0x50 || (instruction.opcode & 0xf0) == 0x60 {
                let target = i as i32 + instruction.offset as i32 + 1;
                if target < 0 || target >= instructions.len() as i32 {
                    return false;
                }
            }
        }
        
        // Check for Solana-specific constraints
        // Maximum program size (roughly 128KB of instructions)
        if instructions.len() > 16384 {
            return false;
        }
        
        true
    }
    
    fn emit_load_reg(&mut self, dst_reg: u8, src_reg: u8, offset: i16) {
        // BPF_LDX | BPF_MEM | BPF_DW (64-bit load)
        let instruction = BpfInstruction::new(0x79, dst_reg, src_reg, offset, 0);
        self.codegen.push(instruction);
    }
    
    fn emit_move_immediate(&mut self, dst_reg: u8, immediate: i32) {
        // BPF_ALU64 | BPF_MOV | BPF_K (64-bit immediate move)
        let instruction = BpfInstruction::new(0xb7, dst_reg, 0, 0, immediate);
        self.codegen.push(instruction);
    }
    
    fn emit_call_function(&mut self, _name: &str) -> Result<(), SolanaError> {
        // For now, emit a call to a generic program function
        // This would be replaced with actual function resolution
        let instruction = BpfInstruction::new(0x85, 0, 0, 0, 1);
        self.codegen.push(instruction);
        Ok(())
    }
    
    fn emit_exit(&mut self) {
        // BPF_JMP | BPF_EXIT
        let instruction = BpfInstruction::new(0x95, 0, 0, 0, 0);
        self.codegen.push(instruction);
    }
    
    pub fn get_instructions(&self) -> &[BpfInstruction] {
        &self.codegen
    }
}