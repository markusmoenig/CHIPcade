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
    
    func toString() -> String {
        switch self {
        case .unsigned16Bit(let unsignedVal):
            return "\(unsignedVal)U"
        case .signed16Bit(let signedVal):
            return "\(signedVal)S"
        case .float16Bit(let float16):
            let float32 = float16ToFloat32(float16)
            return String(format: "%.4fF", float32)
        }
    }
}
