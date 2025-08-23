use thiserror::Error;
use crate::pible::parser::{Node, NodeType};

#[derive(Error, Debug)]
pub enum CodeGenError {
    #[error("Unsupported node type: {0:?}")]
    UnsupportedNodeType(NodeType),
    #[error("Function not found: {0}")]
    FunctionNotFound(String),
    #[error("Invalid instruction: {0}")]
    InvalidInstruction(String),
}

#[derive(Debug, Clone, Copy)]
#[repr(C)]
pub struct BpfInstruction {
    pub opcode: u8,
    pub dst_reg: u8,
    pub src_reg: u8,
    pub offset: i16,
    pub immediate: i32,
}

impl BpfInstruction {
    pub fn new(opcode: u8, dst_reg: u8, src_reg: u8, offset: i16, immediate: i32) -> Self {
        Self {
            opcode,
            dst_reg,
            src_reg,
            offset,
            immediate,
        }
    }

    pub fn to_bytes(&self) -> [u8; 8] {
        let bytes = unsafe { std::mem::transmute::<BpfInstruction, [u8; std::mem::size_of::<BpfInstruction>()]>(*self) };
        // Ensure we return exactly 8 bytes
        let mut result = [0u8; 8];
        for (i, &byte) in bytes.iter().take(8).enumerate() {
            result[i] = byte;
        }
        result
    }
}

// BPF opcodes and instruction classes
#[allow(dead_code)]
mod bpf_opcodes {
    // Instruction classes
    pub const BPF_LD: u8 = 0x00;
    pub const BPF_LDX: u8 = 0x01;
    pub const BPF_ST: u8 = 0x02;
    pub const BPF_STX: u8 = 0x03;
    pub const BPF_ALU: u8 = 0x04;
    pub const BPF_JMP: u8 = 0x05;
    pub const BPF_ALU64: u8 = 0x07;

    // ALU operations
    pub const BPF_ADD: u8 = 0x00;
    pub const BPF_SUB: u8 = 0x10;
    pub const BPF_MUL: u8 = 0x20;
    pub const BPF_DIV: u8 = 0x30;
    pub const BPF_MOD: u8 = 0x90;
    pub const BPF_MOV: u8 = 0xb0;

    // Jump operations
    pub const BPF_JA: u8 = 0x00;
    pub const BPF_JEQ: u8 = 0x10;
    pub const BPF_JGT: u8 = 0x20;
    pub const BPF_JGE: u8 = 0x30;
    pub const BPF_CALL: u8 = 0x80;
    pub const BPF_EXIT: u8 = 0x90;

    // Source operand
    pub const BPF_K: u8 = 0x00; // immediate
    pub const BPF_X: u8 = 0x08; // register
}

pub struct CodeGen {
    instructions: Vec<BpfInstruction>,
    current_reg: u8,
}

impl CodeGen {
    pub fn new() -> Self {
        Self {
            instructions: Vec::new(),
            current_reg: 1, // R0 is return register
        }
    }

    pub fn generate(&mut self, ast: &Node) -> Result<Vec<BpfInstruction>, CodeGenError> {
        self.visit_node(ast)?;
        
        // Add exit instruction
        self.emit_exit(0);
        
        Ok(self.instructions.clone())
    }

    fn visit_node(&mut self, node: &Node) -> Result<(), CodeGenError> {
        match node.node_type {
            NodeType::Program => {
                for child in &node.children {
                    self.visit_node(child)?;
                }
            },
            NodeType::FunctionDecl => {
                self.generate_function(node)?;
            },
            NodeType::Block => {
                for child in &node.children {
                    self.visit_node(child)?;
                }
            },
            NodeType::Statement => {
                if let Some(ref value) = node.value {
                    match value.as_str() {
                        "return" => {
                            if !node.children.is_empty() {
                                self.visit_node(&node.children[0])?;
                            }
                            self.emit_exit(0);
                        },
                        _ => {
                            for child in &node.children {
                                self.visit_node(child)?;
                            }
                        }
                    }
                } else {
                    for child in &node.children {
                        self.visit_node(child)?;
                    }
                }
            },
            NodeType::Expression => {
                if let Some(ref value) = node.value {
                    match value.as_str() {
                        "call" => {
                            self.generate_call(node)?;
                        },
                        _ => {
                            for child in &node.children {
                                self.visit_node(child)?;
                            }
                        }
                    }
                } else {
                    for child in &node.children {
                        self.visit_node(child)?;
                    }
                }
            },
            NodeType::Identifier => {
                // Handle identifiers - for now just placeholder
            },
            NodeType::Literal => {
                // Handle literals - for now just placeholder
            },
        }
        Ok(())
    }

    fn generate_function(&mut self, node: &Node) -> Result<(), CodeGenError> {
        // For now, just process the function body
        if let Some(body) = node.children.last() {
            self.visit_node(body)?;
        }
        Ok(())
    }

    fn generate_call(&mut self, node: &Node) -> Result<(), CodeGenError> {
        if let Some(callee) = node.children.first() {
            if let Some(ref value) = callee.value {
                match value.as_str() {
                    "PrintF" => {
                        // Generate BPF helper call for printing
                        self.emit_call(6); // BPF_FUNC_trace_printk
                    },
                    _ => {
                        // Other function calls - for now just emit a placeholder
                        self.emit_call(1);
                    }
                }
            }
        }
        Ok(())
    }

    fn emit_instruction(&mut self, opcode: u8, dst_reg: u8, src_reg: u8, offset: i16, immediate: i32) {
        let instruction = BpfInstruction::new(opcode, dst_reg, src_reg, offset, immediate);
        self.instructions.push(instruction);
    }

    fn emit_move_immediate(&mut self, dst_reg: u8, immediate: i32) {
        self.emit_instruction(
            bpf_opcodes::BPF_ALU64 | bpf_opcodes::BPF_MOV | bpf_opcodes::BPF_K,
            dst_reg,
            0,
            0,
            immediate,
        );
    }

    fn emit_call(&mut self, func_id: i32) {
        self.emit_instruction(
            bpf_opcodes::BPF_JMP | bpf_opcodes::BPF_CALL,
            0,
            0,
            0,
            func_id,
        );
    }

    fn emit_exit(&mut self, exit_code: i32) {
        // Move exit code to R0
        self.emit_move_immediate(0, exit_code);
        // Exit instruction
        self.emit_instruction(
            bpf_opcodes::BPF_JMP | bpf_opcodes::BPF_EXIT,
            0,
            0,
            0,
            0,
        );
    }

    pub fn validate_instructions(&self, instructions: &[BpfInstruction]) -> bool {
        // Basic validation - check for invalid opcodes
        for instruction in instructions {
            let class = instruction.opcode & 0x07;
            match class {
                bpf_opcodes::BPF_LD | bpf_opcodes::BPF_LDX | 
                bpf_opcodes::BPF_ST | bpf_opcodes::BPF_STX |
                bpf_opcodes::BPF_ALU | bpf_opcodes::BPF_JMP | 
                bpf_opcodes::BPF_ALU64 => {
                    // Valid instruction class
                },
                _ => return false,
            }
        }
        true
    }
}