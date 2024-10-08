//
//  Value.swift
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//

enum ChipCadeData: Codable  {
    case unsigned16Bit(UInt16)   // 16-bit unsigned integer, used for all unsigned and color values
    case signed16Bit(Int16)      // 16-bit signed integer
    case float16Bit(UInt16)      // 16-bit float stored as UInt16 bits

    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case unsigned16Bit, signed16Bit, float16Bit
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

    // Convert to unsigned 16-bit integer
    func toUnsigned16Bit() -> ChipCadeData? {
        switch self {
        case .unsigned16Bit(let unsignedVal):
            return .unsigned16Bit(unsignedVal)

        case .signed16Bit(let signedVal):
            return .unsigned16Bit(UInt16(clamping: signedVal))  // Clamp to 0 for negative values

        case .float16Bit(let float16):
            let float32 = float16ToFloat32(float16)
            return .unsigned16Bit(UInt16(clamping: Int(float32)))  // Clamp float to 16-bit range
        }
    }

    // Convert to signed 16-bit integer
    func toSigned16Bit() -> ChipCadeData? {
        switch self {
        case .unsigned16Bit(let unsignedVal):
            return .signed16Bit(Int16(clamping: unsignedVal))  // Handle overflow

        case .signed16Bit(let signedVal):
            return .signed16Bit(signedVal)

        case .float16Bit(let float16):
            let float32 = float16ToFloat32(float16)
            return .signed16Bit(Int16(clamping: Int(float32)))
        }
    }

    
    // Convert to 16-bit float
    func toFloat16Bit() -> ChipCadeData? {
        switch self {
        case .unsigned16Bit(let unsignedVal):
            let float32 = Float(unsignedVal)
            let float16 = float32ToFloat16(float32)
            return .float16Bit(float16)

        case .signed16Bit(let signedVal):
            let float32 = Float(signedVal)
            let float16 = float32ToFloat16(float32)
            return .float16Bit(float16)

        case .float16Bit(let float16):
            return .float16Bit(float16)
        }
    }
    
    // Convert to 32-bit float
    func toFloat32Bit() -> Float {
        switch self {
        case .unsigned16Bit(let unsignedVal):
            return Float(unsignedVal)

        case .signed16Bit(let signedVal):
            return Float(signedVal)

        case .float16Bit(let float16):
            return float16ToFloat32(float16)
        }
    }
    
    // Converts to UInt16, if possible
    func toUInt16() -> UInt16? {
        switch self {
        case .unsigned16Bit(let value):
            return value
        case .signed16Bit(let value):
            return UInt16(bitPattern: value) // Convert signed to unsigned
        case .float16Bit(let value):
            return value // Treat float as raw UInt16
        }
    }


    // MARK: - Static Function for 32-bit Color to 16-bit Conversion

    // Converts a 24-bit color (RGB) into a 16-bit unsigned value (RGB 5-6-5)
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
    
    // Convert 32-bit float to 16-bit float
    func float32ToFloat16(_ value: Float) -> UInt16 {
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
    
    // Clones the data
    func clone() -> ChipCadeData {
        switch self {
        case .unsigned16Bit(let unsignedVal):
            return .unsigned16Bit(unsignedVal)
        case .signed16Bit(let signedVal):
            return .signed16Bit(signedVal)
        case .float16Bit(let float16):
            return .float16Bit(float16)
        }
    }

    // MARK: - Description for Debugging

    func description() -> String {
        switch self {
        case .unsigned16Bit(let unsignedVal):
            return "Unsigned 16-bit: \(unsignedVal)"
        case .signed16Bit(let signedVal):
            return "Signed 16-bit: \(signedVal)"
        case .float16Bit(let float16):
            return String(format: "Float16: 0x%04X", float16)
        }
    }
    
    func toString(_ identifier: Bool = true) -> String {
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
        }
    }
    
    func toHexString() -> String {
        switch self {
        case .unsigned16Bit(let value):
            return String(format: "0x%04X", value)
        case .signed16Bit(let value):
            return String(format: "0x%04X", UInt16(bitPattern: value))  // Convert signed to hex
        case .float16Bit(let value):
            return String(format: "0x%04X", value)  // Treat the raw bits as hex
        }
    }

    func toBinaryString() -> String {
        switch self {
        case .unsigned16Bit(let value):
            return String(value, radix: 2)
        case .signed16Bit(let value):
            return String(UInt16(bitPattern: value), radix: 2)  // Convert signed to binary
        case .float16Bit(let value):
            return String(value, radix: 2)  // Treat the raw bits as binary
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
            let newFloat16 = float32ToFloat16(newFloat32)
            self = .float16Bit(newFloat16)
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
            let newFloat16 = float32ToFloat16(newFloat32)
            self = .float16Bit(newFloat16)
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
            let float16Result = float32ToFloat16(result)
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
            let float16Result = float32ToFloat16(result)
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
            let float16Result = float32ToFloat16(result)
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
            let float16Result = float32ToFloat16(result)
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
            self = .float16Bit(float32ToFloat16(result))

        default:
            return true
        }

        return false
    }
}

// Conditionals
extension ChipCadeData {

    // Comparison (CMP)
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
