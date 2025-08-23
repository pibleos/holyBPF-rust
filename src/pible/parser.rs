use thiserror::Error;
use crate::pible::lexer::{Token, TokenType};

#[derive(Error, Debug)]
pub enum ParseError {
    #[error("Unexpected token: {0:?} at line {1}")]
    UnexpectedToken(TokenType, usize),
    #[error("Expected token: {expected:?}, found: {found:?} at line {line}")]
    ExpectedToken { expected: TokenType, found: TokenType, line: usize },
    #[error("Unexpected end of file")]
    UnexpectedEof,
}

#[derive(Debug, Clone, PartialEq)]
pub enum NodeType {
    Program,
    FunctionDecl,
    Block,
    Statement,
    Expression,
    Identifier,
    Literal,
}

#[derive(Debug, Clone)]
pub struct Node {
    pub node_type: NodeType,
    pub value: Option<String>,
    pub children: Vec<Node>,
}

impl Node {
    pub fn new(node_type: NodeType) -> Self {
        Self {
            node_type,
            value: None,
            children: Vec::new(),
        }
    }

    pub fn with_value(node_type: NodeType, value: String) -> Self {
        Self {
            node_type,
            value: Some(value),
            children: Vec::new(),
        }
    }

    pub fn add_child(&mut self, child: Node) {
        self.children.push(child);
    }
}

pub struct Parser<'a> {
    tokens: Vec<Token<'a>>,
    current: usize,
}

impl<'a> Parser<'a> {
    pub fn new(tokens: Vec<Token<'a>>) -> Self {
        Self {
            tokens,
            current: 0,
        }
    }

    pub fn parse(&mut self) -> Result<Node, ParseError> {
        let mut program = Node::new(NodeType::Program);
        
        while !self.is_at_end() {
            if let Ok(declaration) = self.declaration() {
                program.add_child(declaration);
            } else {
                // Skip to next declaration on error
                self.synchronize();
            }
        }

        Ok(program)
    }

    fn declaration(&mut self) -> Result<Node, ParseError> {
        if self.match_token(&[TokenType::Export]) {
            self.function_declaration()
        } else if self.check(&TokenType::U0) || self.check(&TokenType::U8) || 
                  self.check(&TokenType::U16) || self.check(&TokenType::U32) || 
                  self.check(&TokenType::U64) {
            self.function_declaration()
        } else {
            self.statement()
        }
    }

    fn function_declaration(&mut self) -> Result<Node, ParseError> {
        // Parse return type
        let return_type_str = self.advance().lexeme.to_string();
        
        // Parse function name
        let name_token = self.consume(TokenType::Identifier, "Expected function name")?;
        let name_str = name_token.lexeme.to_string();
        
        // Parse parameters
        self.consume(TokenType::LeftParen, "Expected '(' after function name")?;
        let mut params = Vec::new();
        
        if !self.check(&TokenType::RightParen) {
            loop {
                // Parse parameter type and name
                let param_type_str = self.advance().lexeme.to_string();
                if self.previous().token_type == TokenType::Star {
                    // Handle pointer types like U8*
                    let _ = self.advance(); // consume the base type
                }
                if self.check(&TokenType::Identifier) {
                    let param_name_token = self.advance();
                    let mut param_node = Node::with_value(NodeType::Identifier, param_name_token.lexeme.to_string());
                    param_node.value = Some(param_type_str);
                    params.push(param_node);
                }
                
                if !self.match_token(&[TokenType::Comma]) {
                    break;
                }
            }
        }
        self.consume(TokenType::RightParen, "Expected ')' after parameters")?;
        
        // Parse function body
        let body = self.block_statement()?;
        
        let mut function = Node::with_value(NodeType::FunctionDecl, format!("{}:{}", return_type_str, name_str));
        for param in params {
            function.add_child(param);
        }
        function.add_child(body);
        
        Ok(function)
    }

    fn statement(&mut self) -> Result<Node, ParseError> {
        if self.match_token(&[TokenType::Return]) {
            self.return_statement()
        } else if self.match_token(&[TokenType::LeftBrace]) {
            self.block_statement()
        } else {
            self.expression_statement()
        }
    }

    fn return_statement(&mut self) -> Result<Node, ParseError> {
        let mut stmt = Node::with_value(NodeType::Statement, "return".to_string());
        
        if !self.check(&TokenType::Semicolon) {
            let expr = self.expression()?;
            stmt.add_child(expr);
        }
        
        self.consume(TokenType::Semicolon, "Expected ';' after return value")?;
        Ok(stmt)
    }

    fn block_statement(&mut self) -> Result<Node, ParseError> {
        let mut block = Node::new(NodeType::Block);
        
        while !self.check(&TokenType::RightBrace) && !self.is_at_end() {
            let stmt = self.declaration()?;
            block.add_child(stmt);
        }
        
        self.consume(TokenType::RightBrace, "Expected '}' after block")?;
        Ok(block)
    }

    fn expression_statement(&mut self) -> Result<Node, ParseError> {
        let expr = self.expression()?;
        self.consume(TokenType::Semicolon, "Expected ';' after expression")?;
        Ok(expr)
    }

    fn expression(&mut self) -> Result<Node, ParseError> {
        self.call()
    }

    fn call(&mut self) -> Result<Node, ParseError> {
        let mut expr = self.primary()?;
        
        while self.match_token(&[TokenType::LeftParen]) {
            expr = self.finish_call(expr)?;
        }
        
        Ok(expr)
    }

    fn finish_call(&mut self, callee: Node) -> Result<Node, ParseError> {
        let mut call = Node::with_value(NodeType::Expression, "call".to_string());
        call.add_child(callee);
        
        if !self.check(&TokenType::RightParen) {
            loop {
                let arg = self.expression()?;
                call.add_child(arg);
                
                if !self.match_token(&[TokenType::Comma]) {
                    break;
                }
            }
        }
        
        self.consume(TokenType::RightParen, "Expected ')' after arguments")?;
        Ok(call)
    }

    fn primary(&mut self) -> Result<Node, ParseError> {
        if self.match_token(&[TokenType::True, TokenType::False]) {
            let token_str = self.previous().lexeme.to_string();
            let mut node = Node::new(NodeType::Literal);
            node.value = Some(token_str);
            Ok(node)
        } else if self.match_token(&[TokenType::NumberLiteral]) {
            let token_str = self.previous().lexeme.to_string();
            let mut node = Node::new(NodeType::Literal);
            node.value = Some(token_str);
            Ok(node)
        } else if self.match_token(&[TokenType::StringLiteral]) {
            let token_str = self.previous().lexeme.to_string();
            let mut node = Node::new(NodeType::Literal);
            node.value = Some(token_str);
            Ok(node)
        } else if self.match_token(&[TokenType::Identifier, TokenType::PrintF]) {
            let token_str = self.previous().lexeme.to_string();
            let mut node = Node::new(NodeType::Identifier);
            node.value = Some(token_str);
            Ok(node)
        } else if self.match_token(&[TokenType::LeftParen]) {
            let expr = self.expression()?;
            self.consume(TokenType::RightParen, "Expected ')' after expression")?;
            Ok(expr)
        } else {
            Err(ParseError::UnexpectedToken(
                self.peek().token_type,
                self.peek().line
            ))
        }
    }

    fn match_token(&mut self, types: &[TokenType]) -> bool {
        for token_type in types {
            if self.check(token_type) {
                self.advance();
                return true;
            }
        }
        false
    }

    fn check(&self, token_type: &TokenType) -> bool {
        if self.is_at_end() {
            false
        } else {
            &self.peek().token_type == token_type
        }
    }

    fn advance(&mut self) -> &Token<'a> {
        if !self.is_at_end() {
            self.current += 1;
        }
        self.previous()
    }

    fn is_at_end(&self) -> bool {
        self.peek().token_type == TokenType::Eof
    }

    fn peek(&self) -> &Token<'a> {
        &self.tokens[self.current]
    }

    fn previous(&self) -> &Token<'a> {
        &self.tokens[self.current - 1]
    }

    fn consume(&mut self, token_type: TokenType, _message: &str) -> Result<&Token<'a>, ParseError> {
        if self.check(&token_type) {
            Ok(self.advance())
        } else {
            Err(ParseError::ExpectedToken {
                expected: token_type,
                found: self.peek().token_type,
                line: self.peek().line,
            })
        }
    }

    fn synchronize(&mut self) {
        self.advance();

        while !self.is_at_end() {
            if self.previous().token_type == TokenType::Semicolon {
                return;
            }

            match self.peek().token_type {
                TokenType::Class | TokenType::For | TokenType::If | 
                TokenType::While | TokenType::Return => return,
                _ => {}
            }

            self.advance();
        }
    }
}