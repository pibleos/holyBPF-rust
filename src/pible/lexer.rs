use std::collections::HashMap;
use thiserror::Error;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[allow(dead_code)]
pub enum TokenType {
    // Keywords
    U0,
    U8,
    U16,
    U32,
    U64,
    I8,
    I16,
    I32,
    I64,
    F64,
    Bool,
    If,
    Else,
    While,
    For,
    Return,
    Break,
    Continue,
    Class,
    Public,
    Private,
    Export,

    // Built-in functions
    PrintF,

    // Symbols
    LeftParen,
    RightParen,
    LeftBrace,
    RightBrace,
    LeftBracket,
    RightBracket,
    Semicolon,
    Comma,
    Dot,
    Plus,
    Minus,
    Star,
    Slash,
    Percent,
    Equal,
    EqualEqual,
    Bang,
    BangEqual,
    Less,
    LessEqual,
    Greater,
    GreaterEqual,
    And,
    Or,

    // Literals
    Identifier,
    StringLiteral,
    NumberLiteral,
    True,
    False,

    // Special
    Eof,
    Invalid,
}

#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct Token<'a> {
    pub token_type: TokenType,
    pub lexeme: &'a str,
    pub line: usize,
    pub column: usize,
}

#[derive(Error, Debug)]
pub enum LexError {
    #[error("Unterminated string at line {0}")]
    UnterminatedString(usize),
    #[error("Invalid character '{0}' at line {1}, column {2}")]
    InvalidCharacter(char, usize, usize),
}

pub struct Lexer<'a> {
    source: &'a str,
    chars: std::str::Chars<'a>,
    current: usize,
    line: usize,
    column: usize,
    start: usize,
    keywords: HashMap<&'static str, TokenType>,
}

impl<'a> Lexer<'a> {
    pub fn new(source: &'a str) -> Self {
        let mut keywords = HashMap::new();
        keywords.insert("U0", TokenType::U0);
        keywords.insert("U8", TokenType::U8);
        keywords.insert("U16", TokenType::U16);
        keywords.insert("U32", TokenType::U32);
        keywords.insert("U64", TokenType::U64);
        keywords.insert("I8", TokenType::I8);
        keywords.insert("I16", TokenType::I16);
        keywords.insert("I32", TokenType::I32);
        keywords.insert("I64", TokenType::I64);
        keywords.insert("F64", TokenType::F64);
        keywords.insert("Bool", TokenType::Bool);
        keywords.insert("if", TokenType::If);
        keywords.insert("else", TokenType::Else);
        keywords.insert("while", TokenType::While);
        keywords.insert("for", TokenType::For);
        keywords.insert("return", TokenType::Return);
        keywords.insert("break", TokenType::Break);
        keywords.insert("continue", TokenType::Continue);
        keywords.insert("class", TokenType::Class);
        keywords.insert("public", TokenType::Public);
        keywords.insert("private", TokenType::Private);
        keywords.insert("export", TokenType::Export);
        keywords.insert("true", TokenType::True);
        keywords.insert("false", TokenType::False);
        keywords.insert("PrintF", TokenType::PrintF);

        Self {
            source,
            chars: source.chars(),
            current: 0,
            line: 1,
            column: 1,
            start: 0,
            keywords,
        }
    }

    pub fn scan_tokens(&mut self) -> Result<Vec<Token<'a>>, LexError> {
        let mut tokens = Vec::new();

        while !self.is_at_end() {
            self.start = self.current;
            self.scan_token(&mut tokens)?;
        }

        tokens.push(Token {
            token_type: TokenType::Eof,
            lexeme: "",
            line: self.line,
            column: self.column,
        });

        Ok(tokens)
    }

    fn scan_token(&mut self, tokens: &mut Vec<Token<'a>>) -> Result<(), LexError> {
        let c = self.advance();

        match c {
            '(' => self.add_token(tokens, TokenType::LeftParen),
            ')' => self.add_token(tokens, TokenType::RightParen),
            '{' => self.add_token(tokens, TokenType::LeftBrace),
            '}' => self.add_token(tokens, TokenType::RightBrace),
            '[' => self.add_token(tokens, TokenType::LeftBracket),
            ']' => self.add_token(tokens, TokenType::RightBracket),
            ';' => self.add_token(tokens, TokenType::Semicolon),
            ',' => self.add_token(tokens, TokenType::Comma),
            '.' => self.add_token(tokens, TokenType::Dot),
            '+' => self.add_token(tokens, TokenType::Plus),
            '-' => self.add_token(tokens, TokenType::Minus),
            '*' => self.add_token(tokens, TokenType::Star),
            '%' => self.add_token(tokens, TokenType::Percent),
            '/' => {
                if self.match_char('/') {
                    // Comment until end of line
                    while !self.is_at_end() && self.peek() != '\n' {
                        self.advance();
                    }
                } else {
                    self.add_token(tokens, TokenType::Slash);
                }
            }
            '=' => {
                let token_type = if self.match_char('=') {
                    TokenType::EqualEqual
                } else {
                    TokenType::Equal
                };
                self.add_token(tokens, token_type);
            }
            '!' => {
                let token_type = if self.match_char('=') {
                    TokenType::BangEqual
                } else {
                    TokenType::Bang
                };
                self.add_token(tokens, token_type);
            }
            '<' => {
                let token_type = if self.match_char('=') {
                    TokenType::LessEqual
                } else {
                    TokenType::Less
                };
                self.add_token(tokens, token_type);
            }
            '>' => {
                let token_type = if self.match_char('=') {
                    TokenType::GreaterEqual
                } else {
                    TokenType::Greater
                };
                self.add_token(tokens, token_type);
            }
            '&' => {
                if self.match_char('&') {
                    self.add_token(tokens, TokenType::And);
                }
            }
            '|' => {
                if self.match_char('|') {
                    self.add_token(tokens, TokenType::Or);
                }
            }
            ' ' | '\r' | '\t' => {
                // Ignore whitespace
            }
            '\n' => {
                self.line += 1;
                self.column = 1;
            }
            '"' => self.string(tokens)?,
            _ => {
                if c.is_ascii_digit() {
                    self.number(tokens);
                } else if c.is_ascii_alphabetic() || c == '_' {
                    self.identifier(tokens);
                } else {
                    return Err(LexError::InvalidCharacter(c, self.line, self.column));
                }
            }
        }

        Ok(())
    }

    fn string(&mut self, tokens: &mut Vec<Token<'a>>) -> Result<(), LexError> {
        while !self.is_at_end() && self.peek() != '"' {
            if self.peek() == '\n' {
                self.line += 1;
                self.column = 1;
            }
            self.advance();
        }

        if self.is_at_end() {
            return Err(LexError::UnterminatedString(self.line));
        }

        self.advance(); // Closing quote
        self.add_token(tokens, TokenType::StringLiteral);
        Ok(())
    }

    fn number(&mut self, tokens: &mut Vec<Token<'a>>) {
        while !self.is_at_end() && self.peek().is_ascii_digit() {
            self.advance();
        }

        if !self.is_at_end() && self.peek() == '.' && self.peek_next().is_ascii_digit() {
            self.advance(); // Consume the '.'
            while !self.is_at_end() && self.peek().is_ascii_digit() {
                self.advance();
            }
        }

        self.add_token(tokens, TokenType::NumberLiteral);
    }

    fn identifier(&mut self, tokens: &mut Vec<Token<'a>>) {
        while !self.is_at_end() && (self.peek().is_ascii_alphanumeric() || self.peek() == '_') {
            self.advance();
        }

        let text = &self.source[self.start..self.current];
        let token_type = self
            .keywords
            .get(text)
            .copied()
            .unwrap_or(TokenType::Identifier);
        self.add_token(tokens, token_type);
    }

    fn add_token(&mut self, tokens: &mut Vec<Token<'a>>, token_type: TokenType) {
        let lexeme = &self.source[self.start..self.current];
        tokens.push(Token {
            token_type,
            lexeme,
            line: self.line,
            column: self.column,
        });
        self.column += lexeme.len();
    }

    fn advance(&mut self) -> char {
        let current_char = self.chars.next().unwrap_or('\0');
        self.current += current_char.len_utf8();
        self.column += 1;
        current_char
    }

    fn match_char(&mut self, expected: char) -> bool {
        if self.is_at_end() || self.peek() != expected {
            return false;
        }
        self.advance();
        true
    }

    fn peek(&self) -> char {
        self.source.chars().nth(self.current).unwrap_or('\0')
    }

    fn peek_next(&self) -> char {
        self.source.chars().nth(self.current + 1).unwrap_or('\0')
    }

    fn is_at_end(&self) -> bool {
        self.current >= self.source.len()
    }
}
