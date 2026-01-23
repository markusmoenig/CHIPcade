#![allow(mismatched_lifetime_syntaxes)]

#[cfg(test)]
mod tests;

use nom::bytes::complete::{tag, tag_no_case, take_while1};
use nom::character::complete::{multispace0, multispace1};
use nom::combinator::{map, opt};
use nom::sequence::preceded;
use nom::{IResult, Parser, branch::alt};

use super::tokens::*;

type Res<'a, T> = IResult<&'a [u8], T>;

#[allow(dead_code)]
pub fn parse_lines<'a>(input: &'a [u8]) -> Res<'a, Vec<OpCode>> {
    let mut codes = Vec::new();
    let mut rest = input;
    while !rest.is_empty() {
        let (r, _) = multispace0.parse(rest)?;
        rest = r;
        if rest.is_empty() {
            break;
        }
        let (r, op) = opcode.parse(rest)?;
        codes.push(op);
        let (r, _) = multispace0.parse(r)?;
        rest = r;
    }
    Ok((rest, codes))
}

pub fn parse_opcode_line<'a>(input: &'a [u8]) -> Res<'a, OpCode> {
    opcode.parse(input)
}

fn opcode<'a>(input: &'a [u8]) -> Res<'a, OpCode> {
    let (input, _) = multispace0.parse(input)?;
    let (input, mnemonic) = mnemonic(input)?;
    let (input, mode_opt) = opt(preceded(multispace1, addressing_mode)).parse(input)?;
    let mode = mode_opt.unwrap_or(AddressingMode::Implied);
    let (input, _) = multispace0.parse(input)?;
    Ok((input, OpCode(mnemonic, mode)))
}

fn mnemonic<'a>(input: &'a [u8]) -> Res<'a, Mnemonic> {
    let (rest, token) = take_while1(is_alpha).parse(input)?;
    let name = std::str::from_utf8(token)
        .unwrap_or("")
        .to_ascii_uppercase();
    let mnem = match name.as_str() {
        "ADC" => Mnemonic::Adc,
        "AND" => Mnemonic::And,
        "ASL" => Mnemonic::Asl,
        "BCC" => Mnemonic::Bcc,
        "BCS" => Mnemonic::Bcs,
        "BEQ" => Mnemonic::Beq,
        "BIT" => Mnemonic::Bit,
        "BMI" => Mnemonic::Bmi,
        "BNE" => Mnemonic::Bne,
        "BPL" => Mnemonic::Bpl,
        "BRK" => Mnemonic::Brk,
        "BVC" => Mnemonic::Bvc,
        "BVS" => Mnemonic::Bvs,
        "CLC" => Mnemonic::Clc,
        "CLD" => Mnemonic::Cld,
        "CLI" => Mnemonic::Cli,
        "CLV" => Mnemonic::Clv,
        "CMP" => Mnemonic::Cmp,
        "CPX" => Mnemonic::Cpx,
        "CPY" => Mnemonic::Cpy,
        "DEC" => Mnemonic::Dec,
        "DEX" => Mnemonic::Dex,
        "DEY" => Mnemonic::Dey,
        "EOR" => Mnemonic::Eor,
        "INC" => Mnemonic::Inc,
        "INX" => Mnemonic::Inx,
        "INY" => Mnemonic::Iny,
        "JMP" => Mnemonic::Jmp,
        "JSR" => Mnemonic::Jsr,
        "LDA" => Mnemonic::Lda,
        "LDX" => Mnemonic::Ldx,
        "LDY" => Mnemonic::Ldy,
        "LSR" => Mnemonic::Lsr,
        "NOP" => Mnemonic::Nop,
        "ORA" => Mnemonic::Ora,
        "PHA" => Mnemonic::Pha,
        "PHP" => Mnemonic::Php,
        "PLA" => Mnemonic::Pla,
        "PLP" => Mnemonic::Plp,
        "ROL" => Mnemonic::Rol,
        "ROR" => Mnemonic::Ror,
        "RTI" => Mnemonic::Rti,
        "RTS" => Mnemonic::Rts,
        "SBC" => Mnemonic::Sbc,
        "SEC" => Mnemonic::Sec,
        "SED" => Mnemonic::Sed,
        "SEI" => Mnemonic::Sei,
        "STA" => Mnemonic::Sta,
        "STX" => Mnemonic::Stx,
        "STY" => Mnemonic::Sty,
        "TAX" => Mnemonic::Tax,
        "TAY" => Mnemonic::Tay,
        "TSX" => Mnemonic::Tsx,
        "TXA" => Mnemonic::Txa,
        "TXS" => Mnemonic::Txs,
        "TYA" => Mnemonic::Tya,
        _ => {
            return Err(nom::Err::Error(nom::error::Error::new(
                input,
                nom::error::ErrorKind::Fail,
            )));
        }
    };
    Ok((rest, mnem))
}

fn addressing_mode<'a>(input: &'a [u8]) -> Res<'a, AddressingMode> {
    let (input, _) = multispace0.parse(input)?;
    if input.is_empty() || input.starts_with(b"\n") || input.starts_with(b"\r") {
        return Ok((input, AddressingMode::Implied));
    }
    alt((
        accumulator,
        immediate,
        indirect_indexed,
        indexed_indirect,
        indirect,
        abs_x,
        abs_y,
        absolute,
        zp_x,
        zp_y,
        zp_or_relative,
    ))
    .parse(input)
}

fn accumulator(input: &[u8]) -> Res<AddressingMode> {
    map(tag_no_case("A"), |_| AddressingMode::Accumulator).parse(input)
}

fn immediate(input: &[u8]) -> Res<AddressingMode> {
    let (input, _) = tag("#")(input)?;
    let (input, (byte, sign)) = alt((
        map(preceded(tag(">"), symbol), |_| (0u8, Sign::Implied)),
        map(preceded(tag("<"), symbol), |_| (0u8, Sign::Implied)),
        parse_byte_hex,
        parse_byte_bin,
        parse_byte_char,
        parse_byte_dec,
        map(symbol, |_| (0u8, Sign::Implied)),
    ))
    .parse(input)?;
    Ok((input, AddressingMode::Immediate(byte, sign)))
}

fn indirect(input: &[u8]) -> Res<AddressingMode> {
    (
        tag("("),
        multispace0,
        parse_word_value_loose,
        multispace0,
        tag(")"),
    )
        .map(|(_, _, word, _, _)| AddressingMode::Indirect(word))
        .parse(input)
}

fn indexed_indirect(input: &[u8]) -> Res<AddressingMode> {
    (
        tag("("),
        multispace0,
        parse_byte_value,
        multispace0,
        tag_no_case(",X"),
        multispace0,
        tag(")"),
    )
        .map(|(_, _, (b, _), _, _, _, _)| AddressingMode::IndexedIndirect(b))
        .parse(input)
}

fn indirect_indexed(input: &[u8]) -> Res<AddressingMode> {
    (
        tag("("),
        multispace0,
        parse_byte_value,
        multispace0,
        tag(")"),
        multispace0,
        tag_no_case(",Y"),
    )
        .map(|(_, _, (b, _), _, _, _, _)| AddressingMode::IndirectIndexed(b))
        .parse(input)
}

fn zp_x(input: &[u8]) -> Res<AddressingMode> {
    (parse_byte_value, multispace0, tag_no_case(",X"))
        .map(|((b, _), _, _)| AddressingMode::ZeroPageX(b))
        .parse(input)
}

fn zp_y(input: &[u8]) -> Res<AddressingMode> {
    (parse_byte_value, multispace0, tag_no_case(",Y"))
        .map(|((b, _), _, _)| AddressingMode::ZeroPageY(b))
        .parse(input)
}

fn abs_x(input: &[u8]) -> Res<AddressingMode> {
    (parse_word_value, multispace0, tag_no_case(",X"))
        .map(|(w, _, _)| AddressingMode::AbsoluteX(w))
        .parse(input)
}

fn abs_y(input: &[u8]) -> Res<AddressingMode> {
    (parse_word_value, multispace0, tag_no_case(",Y"))
        .map(|(w, _, _)| AddressingMode::AbsoluteY(w))
        .parse(input)
}

fn absolute(input: &[u8]) -> Res<AddressingMode> {
    map(parse_word_value, AddressingMode::Absolute).parse(input)
}

fn zp_or_relative(input: &[u8]) -> Res<AddressingMode> {
    map(parse_byte_value, |(b, sign)| {
        AddressingMode::ZeroPageOrRelative(b, sign)
    })
    .parse(input)
}

fn parse_word_value(input: &[u8]) -> Res<u16> {
    alt((
        parse_word_hex,
        parse_word_bin,
        parse_word_dec,
        map(symbol, |_| 0u16),
    ))
    .parse(input)
}

fn parse_word_value_loose(input: &[u8]) -> Res<u16> {
    alt((
        parse_word_hex_loose,
        parse_word_bin_loose,
        parse_word_dec_loose,
        map(symbol, |_| 0u16),
    ))
    .parse(input)
}

fn parse_byte_value(input: &[u8]) -> Res<(u8, Sign)> {
    alt((
        parse_byte_hex,
        parse_byte_bin,
        parse_byte_dec,
        parse_byte_char,
        map(symbol, |_| (0u8, Sign::Implied)),
    ))
    .parse(input)
}

fn parse_byte_hex(input: &[u8]) -> Res<(u8, Sign)> {
    let (input, _) = tag("$")(input)?;
    let (input, digits) = take_while1(is_hex_digit)(input)?;
    if digits.len() > 2 {
        return Err(nom::Err::Error(nom::error::Error::new(
            input,
            nom::error::ErrorKind::Fail,
        )));
    }
    let val = u16::from_str_radix(std::str::from_utf8(digits).unwrap_or(""), 16)
        .map_err(|_| nom::Err::Error(nom::error::Error::new(input, nom::error::ErrorKind::Fail)))?;
    if val > u8::MAX as u16 {
        return Err(nom::Err::Error(nom::error::Error::new(
            input,
            nom::error::ErrorKind::Fail,
        )));
    }
    Ok((input, (val as u8, Sign::Implied)))
}

fn parse_word_hex(input: &[u8]) -> Res<u16> {
    let (input, _) = tag("$")(input)?;
    let (input, digits) = take_while1(is_hex_digit)(input)?;
    if digits.len() <= 2 {
        return Err(nom::Err::Error(nom::error::Error::new(
            input,
            nom::error::ErrorKind::Fail,
        )));
    }
    let val = u16::from_str_radix(std::str::from_utf8(digits).unwrap_or(""), 16)
        .map_err(|_| nom::Err::Error(nom::error::Error::new(input, nom::error::ErrorKind::Fail)))?;
    Ok((input, val))
}

fn parse_word_hex_loose(input: &[u8]) -> Res<u16> {
    let (input, _) = tag("$")(input)?;
    let (input, digits) = take_while1(is_hex_digit)(input)?;
    let val = u16::from_str_radix(std::str::from_utf8(digits).unwrap_or(""), 16)
        .map_err(|_| nom::Err::Error(nom::error::Error::new(input, nom::error::ErrorKind::Fail)))?;
    Ok((input, val))
}

fn parse_byte_bin(input: &[u8]) -> Res<(u8, Sign)> {
    let (input, _) = alt((tag("%"), tag("0b"), tag("0B"))).parse(input)?;
    let (input, digits) = take_while1(is_bin_digit)(input)?;
    if digits.len() > 8 {
        return Err(nom::Err::Error(nom::error::Error::new(
            input,
            nom::error::ErrorKind::Fail,
        )));
    }
    let val = u16::from_str_radix(std::str::from_utf8(digits).unwrap_or(""), 2)
        .map_err(|_| nom::Err::Error(nom::error::Error::new(input, nom::error::ErrorKind::Fail)))?;
    if val > u8::MAX as u16 {
        return Err(nom::Err::Error(nom::error::Error::new(
            input,
            nom::error::ErrorKind::Fail,
        )));
    }
    Ok((input, (val as u8, Sign::Implied)))
}

fn parse_word_bin(input: &[u8]) -> Res<u16> {
    let (input, _) = alt((tag("%"), tag("0b"), tag("0B"))).parse(input)?;
    let (input, digits) = take_while1(is_bin_digit)(input)?;
    if digits.len() <= 8 {
        return Err(nom::Err::Error(nom::error::Error::new(
            input,
            nom::error::ErrorKind::Fail,
        )));
    }
    let val = u32::from_str_radix(std::str::from_utf8(digits).unwrap_or(""), 2)
        .map_err(|_| nom::Err::Error(nom::error::Error::new(input, nom::error::ErrorKind::Fail)))?;
    if val > u16::MAX as u32 {
        return Err(nom::Err::Error(nom::error::Error::new(
            input,
            nom::error::ErrorKind::Fail,
        )));
    }
    Ok((input, val as u16))
}

fn parse_word_bin_loose(input: &[u8]) -> Res<u16> {
    let (input, _) = alt((tag("%"), tag("0b"), tag("0B"))).parse(input)?;
    let (input, digits) = take_while1(is_bin_digit)(input)?;
    let val = u32::from_str_radix(std::str::from_utf8(digits).unwrap_or(""), 2)
        .map_err(|_| nom::Err::Error(nom::error::Error::new(input, nom::error::ErrorKind::Fail)))?;
    Ok((input, val as u16))
}

fn parse_byte_char(input: &[u8]) -> Res<(u8, Sign)> {
    let (input, _) = tag("'")(input)?;
    let (input, ch) = take_while1(|b| b != b'\'')(input)?;
    let (input, _) = tag("'")(input)?;
    Ok((input, (ch[0], Sign::Implied)))
}

fn parse_byte_dec(input: &[u8]) -> Res<(u8, Sign)> {
    let (input, sign) = opt(tag("-")).parse(input)?;
    let (input, digits) = take_while1(is_dec_digit)(input)?;
    if digits.len() > 3 {
        return Err(nom::Err::Error(nom::error::Error::new(
            input,
            nom::error::ErrorKind::Fail,
        )));
    }
    let val = u16::from_str_radix(std::str::from_utf8(digits).unwrap_or(""), 10)
        .map_err(|_| nom::Err::Error(nom::error::Error::new(input, nom::error::ErrorKind::Fail)))?;
    if val > u8::MAX as u16 {
        return Err(nom::Err::Error(nom::error::Error::new(
            input,
            nom::error::ErrorKind::Fail,
        )));
    }
    let sign_flag: Sign = if sign.is_some() {
        Sign::Negative
    } else {
        Sign::Implied
    };
    Ok((input, (val as u8, sign_flag)))
}

fn parse_word_dec(input: &[u8]) -> Res<u16> {
    let (input, digits) = take_while1(is_dec_digit)(input)?;
    let val = u32::from_str_radix(std::str::from_utf8(digits).unwrap_or(""), 10)
        .map_err(|_| nom::Err::Error(nom::error::Error::new(input, nom::error::ErrorKind::Fail)))?;
    if val <= u8::MAX as u32 {
        return Err(nom::Err::Error(nom::error::Error::new(
            input,
            nom::error::ErrorKind::Fail,
        )));
    }
    if val > u16::MAX as u32 {
        return Err(nom::Err::Error(nom::error::Error::new(
            input,
            nom::error::ErrorKind::Fail,
        )));
    }
    Ok((input, val as u16))
}

fn parse_word_dec_loose(input: &[u8]) -> Res<u16> {
    let (input, digits) = take_while1(is_dec_digit)(input)?;
    let val = u32::from_str_radix(std::str::from_utf8(digits).unwrap_or(""), 10)
        .map_err(|_| nom::Err::Error(nom::error::Error::new(input, nom::error::ErrorKind::Fail)))?;
    Ok((input, val as u16))
}

fn symbol(input: &[u8]) -> Res<&[u8]> {
    if input.is_empty() || !(is_alpha(input[0]) || input[0] == b'_') {
        return Err(nom::Err::Error(nom::error::Error::new(
            input,
            nom::error::ErrorKind::Fail,
        )));
    }
    let mut idx = 1;
    while idx < input.len() {
        let b = input[idx];
        if is_alpha(b) || is_dec_digit(b) || b == b'_' {
            idx += 1;
        } else {
            break;
        }
    }
    Ok((&input[idx..], &input[..idx]))
}

fn is_hex_digit(b: u8) -> bool {
    (b'0'..=b'9').contains(&b) || (b'a'..=b'f').contains(&b) || (b'A'..=b'F').contains(&b)
}

fn is_dec_digit(b: u8) -> bool {
    (b'0'..=b'9').contains(&b)
}

fn is_bin_digit(b: u8) -> bool {
    b == b'0' || b == b'1'
}

fn is_alpha(b: u8) -> bool {
    (b'a'..=b'z').contains(&b) || (b'A'..=b'Z').contains(&b)
}
