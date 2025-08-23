use thiserror::Error;
use crate::pible::parser::{Node, NodeType};

#[derive(Error, Debug)]
#[allow(dead_code)]
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
        let mut bytes = [0u8; 8];
        
        // BPF instruction format: [opcode] [dst_reg|src_reg] [offset_lo] [offset_hi] [immediate_bytes]
        bytes[0] = self.opcode;
        bytes[1] = (self.dst_reg & 0x0f) | ((self.src_reg & 0x0f) << 4);
        
        let offset_bytes = self.offset.to_le_bytes();
        bytes[2] = offset_bytes[0];
        bytes[3] = offset_bytes[1];
        
        let immediate_bytes = self.immediate.to_le_bytes();
        bytes[4] = immediate_bytes[0];
        bytes[5] = immediate_bytes[1];
        bytes[6] = immediate_bytes[2];
        bytes[7] = immediate_bytes[3];
        
        bytes
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
                // Process identifier - could be variable reference or function name
                if let Some(ref _value) = node.value {
                    // For identifiers, we might need to load from memory or reference
                    // This is context-dependent and handled by parent nodes
                }
            },
            NodeType::Literal => {
                // Process literal values - numbers, strings, etc.
                if let Some(ref value) = node.value {
                    if let Ok(num) = value.parse::<i32>() {
                        // Numeric literal - load into current register
                        self.emit_move_immediate(self.current_reg, num);
                    }
                    // String literals would need special handling for BPF
                }
            },
        }
        Ok(())
    }

    fn generate_function(&mut self, node: &Node) -> Result<(), CodeGenError> {
        // Generate function prologue and process function body
        if let Some(ref _name) = node.value {
            // Function entry point - could emit function label here
            // For BPF, functions are typically inlined or called via helper functions
        }
        
        // Process function parameters if any
        // Parameters would be in the first children before the body
        
        // Process the function body (last child is typically the block)
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
                        // Set up arguments in registers first
                        if node.children.len() > 1 {
                            // Process arguments and load into appropriate registers
                            for (i, arg) in node.children.iter().skip(1).enumerate() {
                                if i < 5 { // BPF allows up to 5 arguments in R1-R5
                                    self.current_reg = (i + 1) as u8;
                                    self.visit_node(arg)?;
                                }
                            }
                        }
                        self.emit_call(6); // BPF_FUNC_trace_printk
                    },
                    func_name => {
                        // User-defined function call
                        // In BPF, this might be inlined or use a call instruction
                        // For now, emit a generic call with function name hash
                        let func_hash = self.hash_function_name(func_name);
                        self.emit_call(func_hash);
                    }
                }
            }
        }
        Ok(())
    }
    
    fn hash_function_name(&self, name: &str) -> i32 {
        // Simple hash function for function names
        let mut hash = 0i32;
        for byte in name.bytes() {
            hash = hash.wrapping_mul(31).wrapping_add(byte as i32);
        }
        hash.abs() % 1000 + 100 // Keep in a reasonable range for BPF
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