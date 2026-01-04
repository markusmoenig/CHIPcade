#[derive(Debug, Clone, Copy)]
pub struct EvalResult {
    pub value: i64,
}

pub fn eval_expression(expr: &str) -> Result<EvalResult, String> {
    if expr.trim().is_empty() {
        return Err(
            "Empty expression (did the shell strip '$'? try quoting it, e.g. '$12')".to_string(),
        );
    }
    let mut parser = Parser::new(expr);
    let value = parser.parse_expr()?;
    parser.skip_ws();
    if parser.peek.is_some() {
        return Err("Unexpected trailing input".to_string());
    }
    Ok(EvalResult { value })
}

struct Parser<'a> {
    chars: std::str::Chars<'a>,
    peek: Option<char>,
}

impl<'a> Parser<'a> {
    fn new(input: &'a str) -> Self {
        let mut chars = input.chars();
        let peek = chars.next();
        Self { chars, peek }
    }

    fn bump(&mut self) -> Option<char> {
        let curr = self.peek;
        self.peek = self.chars.next();
        curr
    }

    fn skip_ws(&mut self) {
        while matches!(self.peek, Some(c) if c.is_whitespace()) {
            self.bump();
        }
    }

    fn parse_expr(&mut self) -> Result<i64, String> {
        let mut value = self.parse_term()?;
        loop {
            self.skip_ws();
            match self.peek {
                Some('+') => {
                    self.bump();
                    value = value
                        .checked_add(self.parse_term()?)
                        .ok_or_else(|| "Addition overflow".to_string())?;
                }
                Some('-') => {
                    self.bump();
                    value = value
                        .checked_sub(self.parse_term()?)
                        .ok_or_else(|| "Subtraction overflow".to_string())?;
                }
                _ => break,
            }
        }
        Ok(value)
    }

    fn parse_term(&mut self) -> Result<i64, String> {
        let mut value = self.parse_factor()?;
        loop {
            self.skip_ws();
            match self.peek {
                Some('*') => {
                    self.bump();
                    value = value
                        .checked_mul(self.parse_factor()?)
                        .ok_or_else(|| "Multiplication overflow".to_string())?;
                }
                Some('/') => {
                    self.bump();
                    let rhs = self.parse_factor()?;
                    if rhs == 0 {
                        return Err("Division by zero".to_string());
                    }
                    value = value / rhs;
                }
                _ => break,
            }
        }
        Ok(value)
    }

    fn parse_factor(&mut self) -> Result<i64, String> {
        self.skip_ws();
        if let Some(op) = self.peek {
            if op == '+' {
                self.bump();
                return self.parse_factor();
            }
            if op == '-' {
                self.bump();
                return self
                    .parse_factor()?
                    .checked_neg()
                    .ok_or_else(|| "Negation overflow".to_string());
            }
        }
        self.parse_primary()
    }

    fn parse_primary(&mut self) -> Result<i64, String> {
        self.skip_ws();
        match self.peek {
            Some('(') => {
                self.bump();
                let val = self.parse_expr()?;
                self.skip_ws();
                match self.bump() {
                    Some(')') => Ok(val),
                    _ => Err("Expected ')'".to_string()),
                }
            }
            Some(_) => self.parse_number(),
            None => Err("Unexpected end of input".to_string()),
        }
    }

    fn parse_number(&mut self) -> Result<i64, String> {
        self.skip_ws();
        let mut buf = String::new();
        while let Some(c) = self.peek {
            if c.is_ascii_hexdigit()
                || c == 'x'
                || c == 'X'
                || c == 'b'
                || c == 'B'
                || c == '$'
                || c == '%'
            {
                buf.push(c);
                self.bump();
            } else if c == '_' {
                self.bump();
            } else if c.is_whitespace() || "+-*/)".contains(c) {
                break;
            } else {
                return Err(format!("Unexpected character '{c}' in number"));
            }
        }

        if buf.is_empty() {
            return Err("Expected number".to_string());
        }

        let (base, digits) = normalize_digits(&buf)?;
        i64::from_str_radix(digits, base)
            .map_err(|e| format!("Failed to parse number `{buf}`: {e}"))
    }
}

fn normalize_digits(raw: &str) -> Result<(u32, &str), String> {
    // Support prefixes: 0x / 0X / $, 0b / 0B / %, else decimal
    if let Some(rest) = raw.strip_prefix("0x").or_else(|| raw.strip_prefix("0X")) {
        return Ok((16, rest));
    }
    if let Some(rest) = raw.strip_prefix('$') {
        return Ok((16, rest));
    }
    if let Some(rest) = raw.strip_prefix("0b").or_else(|| raw.strip_prefix("0B")) {
        return Ok((2, rest));
    }
    if let Some(rest) = raw.strip_prefix('%') {
        return Ok((2, rest));
    }
    Ok((10, raw))
}
