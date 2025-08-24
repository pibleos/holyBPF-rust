//! # Lexer Module
//!
//! HolyC lexical analysis and tokenization for the Pible compiler.
//!
//! This module provides the `Lexer` struct that converts HolyC source code into a stream
//! of tokens that can be processed by the parser. It recognizes all HolyC language constructs
//! including keywords, operators, literals, and identifiers.
//!
//! ## Examples
//!
//! ### Basic Tokenization
//!
//! ```rust
//! use pible::{Lexer, TokenType};
//!
//! let source = "U0 main() { return 0; }";
//! let mut lexer = Lexer::new(source);
//! let tokens = lexer.scan_tokens().unwrap();
//!
//! assert_eq!(tokens[0].token_type, TokenType::U0);
//! assert_eq!(tokens[1].token_type, TokenType::Identifier);
//! assert_eq!(tokens[2].token_type, TokenType::LeftParen);
//! ```
//!
//! ### Error Handling
//!
//! ```rust
//! use pible::{Lexer, LexError};
//!
//! let source = r#"U0 main() { PrintF("unterminated string; }"#;
//! let mut lexer = Lexer::new(source);
//! 
//! match lexer.scan_tokens() {
//!     Ok(tokens) => println!("Tokenization successful"),
//!     Err(LexError::UnterminatedString(line)) => {
//!         println!("Unterminated string at line {}", line);
//!     }
//!     Err(err) => println!("Other error: {}", err),
//! }
//! ```

use std::collections::HashMap;
use thiserror::Error;

/// HolyC token types recognized by the lexer.
///
/// Represents all possible tokens in the HolyC language including keywords,
/// operators, literals, and punctuation. Each token type corresponds to a
/// specific language construct or symbol.
///
/// ## Examples
///
/// ```rust
/// use pible::TokenType;
///
/// // Data type keywords
/// assert_ne!(TokenType::U0, TokenType::U64);
/// assert_ne!(TokenType::I32, TokenType::F64);
///
/// // Control flow keywords  
/// assert_ne!(TokenType::If, TokenType::While);
/// assert_ne!(TokenType::Return, TokenType::Break);
///
/// // Operators and punctuation
/// assert_ne!(TokenType::Plus, TokenType::Minus);
/// assert_ne!(TokenType::LeftParen, TokenType::RightParen);
/// ```
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[allow(dead_code)]
pub enum TokenType {
    // === Data Type Keywords ===
    /// Void type (`U0`) - represents no return value
    U0,
    /// 8-bit unsigned integer (`U8`)
    U8,
    /// 16-bit unsigned integer (`U16`)
    U16,
    /// 32-bit unsigned integer (`U32`)
    U32,
    /// 64-bit unsigned integer (`U64`)
    U64,
    /// 8-bit signed integer (`I8`)
    I8,
    /// 16-bit signed integer (`I16`)
    I16,
    /// 32-bit signed integer (`I32`)
    I32,
    /// 64-bit signed integer (`I64`)
    I64,
    /// 64-bit floating point (`F64`)
    F64,
    /// Boolean type (`Bool`)
    Bool,
    
    // === Control Flow Keywords ===
    /// Conditional statement (`if`)
    If,
    /// Alternative branch (`else`)
    Else,
    /// Loop construct (`while`)
    While,
    /// Iteration construct (`for`)
    For,
    /// Function return (`return`)
    Return,
    /// Loop termination (`break`)
    Break,
    /// Loop continuation (`continue`)
    Continue,
    
    // === Object-Oriented Keywords ===
    /// Class declaration (`class`)
    Class,
    /// Public access modifier (`public`)
    Public,
    /// Private access modifier (`private`)
    Private,
    /// Export function for Solana programs (`export`)
    Export,

    // === Built-in Functions ===
    /// Divine print function (`PrintF`)
    PrintF,

    // === Punctuation and Operators ===
    /// Left parenthesis `(`
    LeftParen,
    /// Right parenthesis `)`
    RightParen,
    /// Left brace `{`
    LeftBrace,
    /// Right brace `}`
    RightBrace,
    /// Left bracket `[`
    LeftBracket,
    /// Right bracket `]`
    RightBracket,
    /// Semicolon `;`
    Semicolon,
    /// Comma `,`
    Comma,
    /// Dot `.`
    Dot,
    /// Plus operator `+`
    Plus,
    /// Minus operator `-`
    Minus,
    /// Multiplication operator `*`
    Star,
    /// Division operator `/`
    Slash,
    /// Modulo operator `%`
    Percent,
    /// Assignment operator `=`
    Equal,
    /// Equality operator `==`
    EqualEqual,
    /// Logical NOT operator `!`
    Bang,
    /// Inequality operator `!=`
    BangEqual,
    /// Less than operator `<`
    Less,
    /// Less than or equal operator `<=`
    LessEqual,
    /// Greater than operator `>`
    Greater,
    /// Greater than or equal operator `>=`
    GreaterEqual,
    /// Logical AND operator `&&`
    And,
    /// Logical OR operator `||`
    Or,

    // === Literals and Identifiers ===
    /// Variable, function, or class identifier
    Identifier,
    /// String literal enclosed in quotes
    StringLiteral,
    /// Numeric literal (integer or floating point)
    NumberLiteral,
    /// Boolean true literal
    True,
    /// Boolean false literal
    False,

    // === Special Tokens ===
    /// End of file marker
    Eof,
    /// Invalid or unrecognized token
    Invalid,
}

/// A token representing a unit of HolyC source code.
///
/// Contains the token type, source text, and position information for
/// error reporting and debugging purposes.
///
/// ## Examples
///
/// ```rust
/// use pible::{Token, TokenType};
///
/// // Tokens contain position information for error reporting
/// let token = Token {
///     token_type: TokenType::Identifier,
///     lexeme: "main",
///     line: 1,
///     column: 4,
/// };
///
/// println!("Found {} at line {}, column {}", token.lexeme, token.line, token.column);
/// ```
#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct Token<'a> {
    /// The type of token recognized
    pub token_type: TokenType,
    /// The source text that produced this token
    pub lexeme: &'a str,
    /// Line number in the source file (1-based)
    pub line: usize,
    /// Column number in the line (1-based)
    pub column: usize,
}

/// Lexical analysis errors.
///
/// Represents error conditions that can occur during tokenization of
/// HolyC source code.
///
/// ## Examples
///
/// ```rust
/// use pible::{LexError, Token, TokenType};
///
/// // Handle different types of lexical errors  
/// # fn example<'a>() -> Result<Vec<Token<'a>>, LexError> { Ok(vec![]) }
/// match example() {
///     Ok(tokens) => println!("Tokenization successful"),
///     Err(LexError::UnterminatedString(line)) => {
///         eprintln!("Error: Unterminated string at line {}", line);
///     }
///     Err(LexError::InvalidCharacter(ch, line, col)) => {
///         eprintln!("Error: Invalid character '{}' at line {}, column {}", ch, line, col);
///     }
/// }
/// ```
#[derive(Error, Debug)]
pub enum LexError {
    /// String literal is not properly terminated.
    ///
    /// Occurs when a string literal is opened with a quote but never closed
    /// before the end of the file or line.
    #[error("Unterminated string at line {0}")]
    UnterminatedString(usize),
    
    /// Invalid character encountered in source code.
    ///
    /// Occurs when the lexer encounters a character that is not valid
    /// in HolyC syntax at the current position.
    #[error("Invalid character '{0}' at line {1}, column {2}")]
    InvalidCharacter(char, usize, usize),
}

/// HolyC lexical analyzer.
///
/// Converts HolyC source code into a stream of tokens for parsing.
/// Handles all HolyC language constructs including keywords, operators,
/// literals, and identifiers.
///
/// ## Examples
///
/// ### Basic Usage
///
/// ```rust
/// use pible::{Lexer, TokenType};
///
/// let source = r#"
///     U0 main() {
///         PrintF("Hello, divine world!\n");
///         return 0;
///     }
/// "#;
///
/// let mut lexer = Lexer::new(source);
/// let tokens = lexer.scan_tokens().unwrap();
///
/// // Verify we got the expected tokens
/// assert_eq!(tokens[0].token_type, TokenType::U0);
/// assert_eq!(tokens[1].token_type, TokenType::Identifier);
/// assert_eq!(tokens[1].lexeme, "main");
/// ```
///
/// ### Advanced Tokenization
///
/// ```rust
/// use pible::{Lexer, TokenType};
///
/// let source = "U64 count = 42; if (count > 0) { count = count - 1; }";
/// let mut lexer = Lexer::new(source);
/// let tokens = lexer.scan_tokens().unwrap();
///
/// // Count different token types
/// let identifiers: Vec<_> = tokens.iter()
///     .filter(|t| t.token_type == TokenType::Identifier)
///     .collect();
/// let numbers: Vec<_> = tokens.iter()
///     .filter(|t| t.token_type == TokenType::NumberLiteral) 
///     .collect();
///
/// println!("Found {} identifiers and {} numbers", identifiers.len(), numbers.len());
/// ```
pub struct Lexer<'a> {
    /// Source code being tokenized
    source: &'a str,
    /// Iterator over source characters
    chars: std::str::Chars<'a>,
    /// Current position in source
    current: usize,
    /// Current line number (1-based)
    line: usize,
    /// Current column number (1-based)
    column: usize,
    /// Start position of current token
    start: usize,
    /// Keyword lookup table for efficient recognition
    keywords: HashMap<&'static str, TokenType>,
}

impl<'a> Lexer<'a> {
    /// Creates a new lexer for the given source code.
    ///
    /// Initializes the lexer with a keyword lookup table for efficient
    /// recognition of HolyC reserved words and built-in functions.
    ///
    /// # Arguments
    ///
    /// * `source` - HolyC source code to tokenize
    ///
    /// # Examples
    ///
    /// ```rust
    /// use pible::Lexer;
    ///
    /// let source = "U0 main() { return 0; }";
    /// let lexer = Lexer::new(source);
    /// ```
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

    /// Scans the entire source code and returns a vector of tokens.
    ///
    /// This is the main entry point for lexical analysis. It processes the
    /// source code character by character, recognizing tokens and building
    /// a complete token stream for the parser.
    ///
    /// # Returns
    ///
    /// Returns `Ok(Vec<Token>)` containing all tokens including an EOF token,
    /// or a [`LexError`] if invalid syntax is encountered.
    ///
    /// # Examples
    ///
    /// ```rust
    /// use pible::{Lexer, TokenType};
    ///
    /// let source = "U64 answer = 42;";
    /// let mut lexer = Lexer::new(source);
    /// let tokens = lexer.scan_tokens().unwrap();
    ///
    /// assert_eq!(tokens[0].token_type, TokenType::U64);
    /// assert_eq!(tokens[1].token_type, TokenType::Identifier);
    /// assert_eq!(tokens[1].lexeme, "answer");
    /// assert_eq!(tokens[2].token_type, TokenType::Equal);
    /// assert_eq!(tokens[3].token_type, TokenType::NumberLiteral);
    /// assert_eq!(tokens[3].lexeme, "42");
    /// ```
    ///
    /// # Errors
    ///
    /// This function will return an error if:
    /// - An unterminated string literal is encountered ([`LexError::UnterminatedString`])
    /// - An invalid character is found ([`LexError::InvalidCharacter`])
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
