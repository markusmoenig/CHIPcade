//
//  Value.swift
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//

enum ChipCadeData: Codable {
    case unsigned16Bit(UInt16)   // 16-bit unsigned integer
    case signed16Bit(Int16)      // 16-bit signed integer
    case float16Bit(UInt16)      // 16-bit float stored as UInt16 bits
    case unicodeChar(UInt16)     // 16-bit Unicode character
    case register(UInt16)        // Register Reference, currently 0-11

    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case unsigned16Bit, signed16Bit, float16Bit, unicodeChar, register
    }

    // MARK: - Encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .unsigned16Bit(let value):
            try container.encode(value, forKey: .unsigned16Bit)
        case .signed16Bit(let value):
            try container.encode(value, forKey: .signed16Bit)
        case .float16Bit(let value):
            try container.encode(value, forKey: .float16Bit)
        case .unicodeChar(let value):
            try container.encode(value, forKey: .unicodeChar)
        case .register(let value):
            try container.encode(value, forKey: .register)
        }
    }

    // MARK: - Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let unsignedValue = try? container.decode(UInt16.self, forKey: .unsigned16Bit) {
            self = .unsigned16Bit(unsignedValue)
        } else if let signedValue = try? container.decode(Int16.self, forKey: .signed16Bit) {
            self = .signed16Bit(signedValue)
        } else if let floatValue = try? container.decode(UInt16.self, forKey: .float16Bit) {
            self = .float16Bit(floatValue)
        } else if let unicodeValue = try? container.decode(UInt16.self, forKey: .unicodeChar) {
            self = .unicodeChar(unicodeValue)
        } else if let registerValue = try? container.decode(UInt16.self, forKey: .register) {
            self = .register(registerValue)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unable to decode ChipCadeData."
                )
            )
        }
    }
    
    // MARK: - Conversion Methods

    /// Convert to unsigned 16-bit integer
    func toUnsigned16Bit() -> ChipCadeData? {
        switch self {
        case .unsigned16Bit(let unsignedVal):
            return .unsigned16Bit(unsignedVal)
        case .signed16Bit(let signedVal):
            return .unsigned16Bit(UInt16(clamping: signedVal))
        case .float16Bit(let float16):
            let float32 = float16ToFloat32(float16)
            return .unsigned16Bit(UInt16(clamping: Int(float32)))
        case .unicodeChar(let unicodeVal):
            return .unsigned16Bit(unicodeVal)
        case .register(let register):
            return .unsigned16Bit(register)
        }
    }

    /// Convert to signed 16-bit integer
    func toSigned16Bit() -> ChipCadeData? {
        switch self {
        case .unsigned16Bit(let unsignedVal):
            return .signed16Bit(Int16(clamping: unsignedVal))
        case .signed16Bit(let signedVal):
            return .signed16Bit(signedVal)
        case .float16Bit(let float16):
            let float32 = float16ToFloat32(float16)
            return .signed16Bit(Int16(clamping: Int(float32)))
        case .unicodeChar(let unicodeVal):
            return .signed16Bit(Int16(bitPattern: unicodeVal))
        case .register(let register):
            return .signed16Bit(Int16(register))
        }
    }

    /// Convert to 16-bit float
    func toFloat16Bit() -> ChipCadeData? {
        switch self {
        case .unsigned16Bit(let unsignedVal):
            let float32 = Float(unsignedVal)
            let float16 = ChipCadeData.float32ToFloat16(float32)
            return .float16Bit(float16)
        case .signed16Bit(let signedVal):
            let float32 = Float(signedVal)
            let float16 = ChipCadeData.float32ToFloat16(float32)
            return .float16Bit(float16)
        case .float16Bit(let float16):
            return .float16Bit(float16)
        case .unicodeChar(let unicodeVal):
            let float32 = Float(unicodeVal)
            let float16 = ChipCadeData.float32ToFloat16(float32)
            return .float16Bit(float16)
        case .register(let register):
            return .float16Bit(ChipCadeData.float32ToFloat16(Float(register)))
        }
    }

    /// Convert to 16-bit Unicode character
    func toUnicodeChar() -> ChipCadeData? {
        switch self {
        case .unsigned16Bit(let unsignedVal):
            return .unicodeChar(unsignedVal)
        case .signed16Bit(let signedVal):
            return .unicodeChar(UInt16(bitPattern: signedVal))
        case .float16Bit(let float16):
            let float32 = float16ToFloat32(float16)
            return .unicodeChar(UInt16(clamping: Int(float32)))
        case .unicodeChar(let unicodeVal):
            return .unicodeChar(unicodeVal)
        case .register(let register):
            return .unicodeChar(UInt16(register))
        }
    }

    /// Convert to 32-bit float
    func toFloat32Bit() -> Float {
        switch self {
        case .unsigned16Bit(let unsignedVal):
            return Float(unsignedVal)
        case .signed16Bit(let signedVal):
            return Float(signedVal)
        case .float16Bit(let float16):
            return float16ToFloat32(float16)
        case .unicodeChar(let unicodeVal):
            return Float(unicodeVal)
        case .register(let register):
            return Float(register)
        }
    }

    /// Convert to 32-bit int
    func toInt32Bit() -> Int {
        switch self {
        case .unsigned16Bit(let unsignedVal):
            return Int(unsignedVal)
        case .signed16Bit(let signedVal):
            return Int(signedVal)
        case .float16Bit(let float16):
            return Int(float16ToFloat32(float16))
        case .unicodeChar(let unicodeVal):
            return Int(unicodeVal)
        case .register(let register):
            return Int(register)
        }
    }

    /// Converts to UInt16, if possible
    func toUInt16() -> UInt16? {
        switch self {
        case .unsigned16Bit(let value):
            return value
        case .signed16Bit(let value):
            return UInt16(bitPattern: value)
        case .float16Bit(let value):
            return value
        case .unicodeChar(let value):
            return value
        case .register(let register):
            return register
        }
    }

    /// Convert to Unicode String representation
    func toUnicodeString() -> String? {
        switch self {
        case .unicodeChar(let unicodeVal):
            return String(UnicodeScalar(unicodeVal) ?? "?")
        default:
            return nil
        }
    }

    /// Checks if the value is unsigned
    func isUnsigned() -> Bool {
        switch self {
        case .unsigned16Bit(_):
            return true
        default: return false
        }
    }
    
    /// Checks if the value is an unicode char
    func isUnicode() -> Bool {
        switch self {
        case .unicodeChar(_):
            return true
        default: return false
        }
    }

    // MARK: - Static Function for 32-bit Color to 16-bit Conversion

    /// Converts a 24-bit color (RGB) into a 16-bit unsigned value (RGB 5-6-5)
    func float16ToFloat32(_ float16: UInt16) -> Float {
        let sign = UInt32((float16 >> 15) & 0x1)       // Cast to UInt32
        let exponent = Int((float16 >> 10) & 0x1F)     // Keep as Int for calculation
        let mantissa = UInt32(float16 & 0x3FF)         // Cast to UInt32

        var float32Exponent: Int
        var float32Mantissa: UInt32

        if exponent == 0 {
            if mantissa == 0 {
                // Zero (signed zero)
                float32Exponent = 0
                float32Mantissa = 0
            } else {
                // Subnormal number
                float32Exponent = 127 - 15 + 1 // Adjust for subnormal exponent
                float32Mantissa = mantissa << (23 - 10) // Normalize the mantissa
            }
        } else if exponent == 0x1F {
            // Infinity or NaN
            float32Exponent = 0xFF
            float32Mantissa = mantissa != 0 ? mantissa << (23 - 10) : 0 // NaN or Infinity
        } else {
            // Normalized number
            float32Exponent = exponent - 15 + 127
            float32Mantissa = mantissa << (23 - 10)
        }

        let float32Bits = (sign << 31) | (UInt32(float32Exponent) << 23) | float32Mantissa
        return Float(bitPattern: UInt32(float32Bits))
    }
    
    /// Convert 32-bit float to 16-bit float
    static func float32ToFloat16(_ value: Float) -> UInt16 {
        let bits = value.bitPattern
        let sign = UInt16((bits >> 31) & 0x1)  // Cast sign to UInt16
        let exponent = Int((bits >> 23) & 0xFF) - 127 + 15
        let mantissa = bits & 0x7FFFFF

        // Handle subnormal numbers (exponent < -14)
        if exponent <= 0 {
            // This is a subnormal number in 16-bit float
            let float16Bits = UInt16((sign << 15) | UInt16((mantissa | 0x800000) >> (1 - exponent)))
            return float16Bits
        } else if exponent >= 31 {
            // Handle overflow (exponent >= 31 means infinity or NaN in 16-bit float)
            let float16Bits = UInt16((sign << 15) | UInt16(0x1F << 10))
            return float16Bits
        } else {
            // Normal number
            let float16Bits = UInt16((sign << 15) | UInt16(exponent << 10) | UInt16(mantissa >> 13))
            return float16Bits
        }
    }
    
    /// Clone the data
    func clone() -> ChipCadeData {
        switch self {
        case .unsigned16Bit(let unsignedVal):
            return .unsigned16Bit(unsignedVal)
        case .signed16Bit(let signedVal):
            return .signed16Bit(signedVal)
        case .float16Bit(let float16):
            return .float16Bit(float16)
        case .unicodeChar(let unicodeVal):
            return .unicodeChar(unicodeVal)
        case .register(let register):
            return .register(register)
        }
    }

    /// Convert to String for Debugging
    func description() -> String {
        switch self {
        case .unsigned16Bit(let unsignedVal):
            return "Unsigned 16-bit: \(unsignedVal)"
        case .signed16Bit(let signedVal):
            return "Signed 16-bit: \(signedVal)"
        case .float16Bit(let float16):
            return String(format: "Float16: 0x%04X", float16)
        case .unicodeChar(let unicodeVal):
            return "Unicode Char: \(String(UnicodeScalar(unicodeVal) ?? "?"))"
        case .register(let register):
            return String(format: "Register: R\(register)")
        }
    }
    
    // Convert to a character
    func toChar(_ identifier: Bool = true) -> String {
        switch self {
        case .unicodeChar(let unicodeVal):
            let char = String(UnicodeScalar(unicodeVal) ?? "?")
            return "\(char)"
        default:
            return ""
        }
    }
    
    // Convert to String
    func toString(_ identifier: Bool = true) -> String {
        switch self {
        case .unsigned16Bit(let unsignedVal):
            return identifier ? "\(unsignedVal)u" : "\(unsignedVal)"
        case .signed16Bit(let signedVal):
            return identifier ? "\(signedVal)s" : "\(signedVal)"
        case .float16Bit(let float16):
            let float32 = float16ToFloat32(float16)
            return identifier ? String(format: "%.3ff", float32) : String(format: "%.3f", float32)
        case .unicodeChar(let unicodeVal):
            let char = String(UnicodeScalar(unicodeVal) ?? "?")
//            return identifier ? "\(unicodeVal)uC (\(char))" : "\(char)"
            return "`\(char)`"
        case .register(let register):
            return "R\(register)"
        }
    }
    
    /// Convert to full String representation for Debugging
    func toStringFull(_ identifier: Bool = true) -> String {
        switch self {
        case .unsigned16Bit(let unsignedVal):
            if identifier {
                return String(format: "%05du", unsignedVal) // Always 5 digits, padded with 0s
            } else {
                return String(format: "%05d", unsignedVal) // No identifier, just padded
            }
        case .signed16Bit(let signedVal):
            if identifier {
                return String(format: "%05ds", signedVal) // Always 5 digits, padded with 0s
            } else {
                return String(format: "%05d", signedVal) // No identifier, just padded
            }
        case .float16Bit(let float16):
            let float32 = float16ToFloat32(float16)
            if identifier {
                return String(format: "%.3ff", float32) // Always 3 decimal places with 'f'
            } else {
                return String(format: "%.3f", float32) // No identifier, but always 3 decimals
            }
        case .unicodeChar(let unicodeVal):
            let char = String(UnicodeScalar(unicodeVal) ?? "?")
            if identifier {
                return String(format: "%05duC (\(char))", unicodeVal) // 5 digits + identifier
            } else {
                return String(format: "%05d (\(char))", unicodeVal) // Just padded
            }
        case .register(let register):
            return "R\(register)s"
        }
    }
    
    /// Convert to Hex String
    func toHexString() -> String {
        switch self {
        case .unsigned16Bit(let value):
            return String(format: "0x%04X", value)
        case .signed16Bit(let value):
            return String(format: "0x%04X", UInt16(bitPattern: value))
        case .float16Bit(let value):
            return String(format: "0x%04X", value)
        case .unicodeChar(let value):
            return String(format: "0x%04X", value)
        case .register(let register):
            return String(format: "0x%04X", register)
        }
    }

    /// Convert to Binary String
    func toBinaryString() -> String {
        switch self {
        case .unsigned16Bit(let value):
            return String(value, radix: 2)
        case .signed16Bit(let value):
            return String(UInt16(bitPattern: value), radix: 2)
        case .float16Bit(let value):
            return String(value, radix: 2)
        case .unicodeChar(let value):
            return String(value, radix: 2)
        case .register(let register):
            return String(register, radix: 2)
        }
    }
    
    /// Generates a random value within a given range.
    static func random(upTo maxValue: ChipCadeData) -> ChipCadeData {
        switch maxValue {
        case .unsigned16Bit(let max):
            let randomValue = UInt16.random(in: 0...max)
            return .unsigned16Bit(randomValue)
        case .signed16Bit(let max):
            let randomValue = Int16.random(in: 0...max)
            return .signed16Bit(randomValue)
        case .float16Bit(_):
            let randomValue = Float.random(in: 0.0...maxValue.toFloat32Bit())
            return .float16Bit(float32ToFloat16(randomValue))
        case .unicodeChar(let max):
            let randomValue = UInt16.random(in: 0...max)
            return .unicodeChar(randomValue)
        case .register(let max):
            let randomValue = UInt16.random(in: 0...max)
            return .unsigned16Bit(randomValue)
        }
    }
    
    /// Resolves register based values.
    func resolve(_ game: Game) -> ChipCadeData {
        switch self {
        case .register(let register):
            let reg = register > 7 ? 7 : Int(register)
            return game.registers[reg]
        default: return self
        }
    }
}

// Arithmetic
extension ChipCadeData {

    // Increment function
    mutating func inc(flags: CPUFlags) {
        switch self {
        case .unsigned16Bit(let value):
            let newValue = value &+ 1 // Wrap-around if it exceeds UInt16.max
            flags.setZeroFlag(newValue == 0)
            flags.setCarryFlag(newValue < value) // Carry occurs if the value wrapped around
            self = .unsigned16Bit(newValue)

        case .signed16Bit(let value):
            let newValue = Int16(clamping: value &+ 1)
            flags.setZeroFlag(newValue == 0)
            flags.setOverflowFlag(value == Int16.max) // Overflow if incrementing max value
            flags.setNegativeFlag(newValue < 0)
            self = .signed16Bit(newValue)

        case .float16Bit(let float16):
            let float32 = float16ToFloat32(float16)
            let newFloat32 = float32 + 1.0
            flags.setZeroFlag(newFloat32 == 0)
            flags.setNegativeFlag(newFloat32 < 0)
            let newFloat16 = ChipCadeData.float32ToFloat16(newFloat32)
            self = .float16Bit(newFloat16)

        default: break;
        }
    }

    // Decrement function
    mutating func dec(flags: CPUFlags) {
        switch self {
        case .unsigned16Bit(let value):
            let newValue = value &- 1 // Wrap-around if it goes below 0
            flags.setZeroFlag(newValue == 0)
            flags.setCarryFlag(value == 0) // Carry occurs if decrementing 0
            self = .unsigned16Bit(newValue)

        case .signed16Bit(let value):
            let newValue = Int16(clamping: value &- 1)
            flags.setZeroFlag(newValue == 0)
            flags.setOverflowFlag(value == Int16.min) // Overflow if decrementing min value
            flags.setNegativeFlag(newValue < 0)
            self = .signed16Bit(newValue)

        case .float16Bit(let float16):
            let float32 = float16ToFloat32(float16)
            let newFloat32 = float32 - 1.0
            flags.setZeroFlag(newFloat32 == 0)
            flags.setNegativeFlag(newFloat32 < 0)
            let newFloat16 = ChipCadeData.float32ToFloat16(newFloat32)
            self = .float16Bit(newFloat16)
            
        default: break;
        }
    }
    
    // Addition
    mutating func add(other: ChipCadeData, flags: CPUFlags) -> Bool {
        switch (self, other) {
        case (.unsigned16Bit(let value1), .unsigned16Bit(let value2)):
            let result = value1 &+ value2
            flags.setZeroFlag(result == 0)
            flags.setCarryFlag(result < value1) // Carry if overflow occurred
            self = .unsigned16Bit(result)

        case (.signed16Bit(let value1), .signed16Bit(let value2)):
            let result = Int16(clamping: value1 &+ value2)
            flags.setZeroFlag(result == 0)
            flags.setOverflowFlag((value1 > 0 && value2 > 0 && result < 0) || (value1 < 0 && value2 < 0 && result > 0))
            flags.setNegativeFlag(result < 0)
            self = .signed16Bit(result)

        case (.float16Bit(let float16_1), .float16Bit(let float16_2)):
            let float32_1 = float16ToFloat32(float16_1)
            let float32_2 = float16ToFloat32(float16_2)
            let result = float32_1 + float32_2
            flags.setZeroFlag(result == 0)
            flags.setNegativeFlag(result < 0)
            let float16Result = ChipCadeData.float32ToFloat16(result)
            self = .float16Bit(float16Result)

        default:
            return true
        }
        
        return false
    }

    // Subtraction
    mutating func sub(other: ChipCadeData, flags: CPUFlags) -> Bool {
        switch (self, other) {
        case (.unsigned16Bit(let value1), .unsigned16Bit(let value2)):
            let result = value1 &- value2
            flags.setZeroFlag(result == 0)
            flags.setCarryFlag(value1 < value2) // Carry if underflow occurred
            self = .unsigned16Bit(result)

        case (.signed16Bit(let value1), .signed16Bit(let value2)):
            let result = Int16(clamping: value1 &- value2)
            flags.setZeroFlag(result == 0)
            flags.setOverflowFlag((value1 > 0 && value2 < 0 && result < 0) || (value1 < 0 && value2 > 0 && result > 0))
            flags.setNegativeFlag(result < 0)
            self = .signed16Bit(result)

        case (.float16Bit(let float16_1), .float16Bit(let float16_2)):
            let float32_1 = float16ToFloat32(float16_1)
            let float32_2 = float16ToFloat32(float16_2)
            let result = float32_1 - float32_2
            flags.setZeroFlag(result == 0)
            flags.setNegativeFlag(result < 0)
            let float16Result = ChipCadeData.float32ToFloat16(result)
            self = .float16Bit(float16Result)

        default:
            return true
        }
        
        return false
    }

    // Multiplication
    mutating func mul(other: ChipCadeData, flags: CPUFlags) -> Bool {
        switch (self, other) {
        case (.unsigned16Bit(let value1), .unsigned16Bit(let value2)):
            let result = value1 &* value2
            flags.setZeroFlag(result == 0)
            flags.setCarryFlag(result < value1 || result < value2) // Carry if overflow occurred
            self = .unsigned16Bit(result)
            
        case (.signed16Bit(let value1), .signed16Bit(let value2)):
            let result = Int16(clamping: value1 &* value2)
            flags.setZeroFlag(result == 0)
            flags.setOverflowFlag((value1 > 0 && value2 > 0 && result < 0) || (value1 < 0 && value2 < 0 && result > 0))
            flags.setNegativeFlag(result < 0)
            self = .signed16Bit(result)
            
        case (.float16Bit(let float16_1), .float16Bit(let float16_2)):
            let float32_1 = float16ToFloat32(float16_1)
            let float32_2 = float16ToFloat32(float16_2)
            let result = float32_1 * float32_2
            flags.setZeroFlag(result == 0)
            flags.setNegativeFlag(result < 0)
            let float16Result = ChipCadeData.float32ToFloat16(result)
            self = .float16Bit(float16Result)
            
        default:
            return true
        }

        return false
    }
    
    // Division
    mutating func div(other: ChipCadeData, flags: CPUFlags) -> Bool {
        switch (self, other) {
        case (.unsigned16Bit(let value1), .unsigned16Bit(let value2)):
            if value2 == 0 {
                // Handle division by zero (could set a flag or return an error)
                flags.setCarryFlag(true) // Indicate division by zero error
                return true
            }
            let result = value1 / value2
            flags.setZeroFlag(result == 0)
            flags.setCarryFlag(false) // No carry on division
            self = .unsigned16Bit(result)

        case (.signed16Bit(let value1), .signed16Bit(let value2)):
            if value2 == 0 {
                // Handle division by zero
                flags.setOverflowFlag(true) // Indicate division by zero error
                return true
            }
            let result = Int16(clamping: value1 / value2)
            flags.setZeroFlag(result == 0)
            flags.setOverflowFlag(value1 == Int16.min && value2 == -1) // Overflow if dividing by -1 at the min value
            flags.setNegativeFlag(result < 0)
            self = .signed16Bit(result)

        case (.float16Bit(let float16_1), .float16Bit(let float16_2)):
            let float32_1 = float16ToFloat32(float16_1)
            let float32_2 = float16ToFloat32(float16_2)
            if float32_2 == 0 {
                // Handle division by zero (could return NaN or set a flag)
                flags.setCarryFlag(true) // Division by zero error
                return true
            }
            let result = float32_1 / float32_2
            flags.setZeroFlag(result == 0)
            flags.setNegativeFlag(result < 0)
            let float16Result = ChipCadeData.float32ToFloat16(result)
            self = .float16Bit(float16Result)

        default:
            return true
        }

        return false
    }
    
    // Modulus (MOD)
    mutating func mod(other: ChipCadeData, flags: CPUFlags) -> Bool {
        switch (self, other) {
        case (.unsigned16Bit(let value1), .unsigned16Bit(let value2)):
            if value2 == 0 {
                // Handle division by zero (undefined for mod)
                flags.setCarryFlag(true) // Set carry flag to indicate division by zero error
                return true
            }
            let result = value1 % value2
            flags.setZeroFlag(result == 0)
            flags.setCarryFlag(false) // No carry for successful mod
            self = .unsigned16Bit(result)

        case (.signed16Bit(let value1), .signed16Bit(let value2)):
            if value2 == 0 {
                // Handle division by zero (undefined for mod)
                flags.setOverflowFlag(true) // Set overflow flag to indicate division by zero error
                return true
            }
            let result = value1 % value2
            flags.setZeroFlag(result == 0)
            flags.setNegativeFlag(result < 0) // Set negative flag if result is negative
            flags.setOverflowFlag(false)
            self = .signed16Bit(result)

        case (.float16Bit(let float16_1), .float16Bit(let float16_2)):
            let float32_1 = float16ToFloat32(float16_1)
            let float32_2 = float16ToFloat32(float16_2)
            if float32_2 == 0 {
                // Handle division by zero (undefined for mod)
                flags.setCarryFlag(true) // Set carry flag to indicate division by zero error
                return true
            }
            let result = fmod(float32_1, float32_2) // Use fmod for floating-point modulus
            flags.setZeroFlag(result == 0)
            flags.setNegativeFlag(result < 0)
            self = .float16Bit(ChipCadeData.float32ToFloat16(result))

        default:
            return true
        }

        return false
    }
}

// Conditionals
extension ChipCadeData {

    /// Comparison (CMP)
    func cmp(other: ChipCadeData, flags: CPUFlags) -> Bool {
        switch (self, other) {
        case (.unsigned16Bit(let value1), .unsigned16Bit(let value2)):
            let result = value1 &- value2
            flags.setZeroFlag(result == 0)
            flags.setCarryFlag(value1 < value2) // Set carry if there is a borrow (underflow)

        case (.signed16Bit(let value1), .signed16Bit(let value2)):
            let result = Int16(clamping: value1 &- value2)
            flags.setZeroFlag(result == 0)
            flags.setOverflowFlag((value1 > 0 && value2 < 0 && result < 0) || (value1 < 0 && value2 > 0 && result > 0))
            flags.setNegativeFlag(result < 0)

        case (.float16Bit(let float16_1), .float16Bit(let float16_2)):
            let float32_1 = float16ToFloat32(float16_1)
            let float32_2 = float16ToFloat32(float16_2)
            let result = float32_1 - float32_2
            flags.setZeroFlag(result == 0)
            flags.setNegativeFlag(result < 0)

        default:
            return true
        }

        return false
    }
}

// From String
extension ChipCadeData {
 
    static func fromString(text: String, unsignedDefault: Bool) -> ChipCadeData? {
        
        // Handle registers
        if text.lowercased().hasPrefix("r") {
            if let value = UInt16(text.dropFirst(1)) {
                return .register(value)
            }
        }
        
        // Handle single-character input in quotes or backticks
        if (text.first == "\"" && text.last == "\"") || (text.first == "`" && text.last == "`") {
            let character = text.dropFirst().dropLast()
            if character.count == 1, let unicodeValue = character.unicodeScalars.first?.value, unicodeValue <= UInt16.max {
                return .unicodeChar(UInt16(unicodeValue))
            }
        }
        
        // Handle float values
        if text.contains(".") {
            if let value = Float(text) {
                let float16 = ChipCadeData.float32ToFloat16(value)
                return .float16Bit(float16)
            }
        }
        
        // Handle hexadecimal values (starting with "0x")
        if text.lowercased().hasPrefix("0x") {
            if let value = UInt16(text.dropFirst(2), radix: 16) {
                return .unsigned16Bit(value)
            }
        }
        
        // Handle binary values (starting with "0b" or "%")
        if text.lowercased().hasPrefix("0b") || text.hasPrefix("%") {
            let binaryText = text.starts(with: "%") ? text.dropFirst() : text.dropFirst(2)
            if let value = UInt16(binaryText, radix: 2) {
                return .unsigned16Bit(value)
            }
        }
        
        // Handle signed 16-bit integers
        if text.hasPrefix("-") {
            if let value = Int16(text) {
                return .signed16Bit(value)
            }
        }
        
        // Handle unsigned 16-bit integers with suffixes
        if text.hasSuffix("u") {
            if let value = UInt16(text.dropLast()) {
                return .unsigned16Bit(value)
            }
        }
        
        // Handle signed 16-bit integers with suffixes
        if text.hasSuffix("s") {
            if let value = Int16(text.dropLast()) {
                return .signed16Bit(value)
            }
        }
        
        // Handle 16-bit float values with suffixes
        if text.hasSuffix("f") {
            if let value = Float(text.dropLast()) {
                let float16 = ChipCadeData.float32ToFloat16(value)
                return .float16Bit(float16)
            }
        }
        
        if unsignedDefault {
            if let value = UInt16(text) {
                return .unsigned16Bit(value)
            }
        }
     
        return nil
    }
}
