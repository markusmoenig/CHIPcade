//
//  Instruction.swift
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//

import Foundation

struct InstrMeta : Codable {
    
}

enum Instruction: Codable {
    case ldi(InstrMeta?, Int8, ChipCadeData)
    case push(InstrMeta?, ChipCadeData)
    case nop(InstrMeta?)
    
    enum CodingKeys: String, CodingKey {
        case type
        case meta
        case register
        case value
    }

    enum InstructionType: String, Codable {
        case ldi
        case push
        case nop
    }

    // Encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode the case type
        switch self {
        case .ldi(let meta, let register, let value):
            try container.encode(InstructionType.ldi, forKey: .type)
            try container.encodeIfPresent(meta, forKey: .meta)
            try container.encode(register, forKey: .register)
            try container.encode(value, forKey: .value)
        case .push(let meta, let value):
            try container.encode(InstructionType.push, forKey: .type)
            try container.encodeIfPresent(meta, forKey: .meta)
            try container.encode(value, forKey: .value)
        case .nop(let meta):
            try container.encode(InstructionType.nop, forKey: .type)
            try container.encodeIfPresent(meta, forKey: .meta)
        }
    }
    
    // Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(InstructionType.self, forKey: .type)
        
        switch type {
        case .ldi:
            let meta = try container.decodeIfPresent(InstrMeta.self, forKey: .meta)
            let register = try container.decode(Int8.self, forKey: .register)
            let value = try container.decode(ChipCadeData.self, forKey: .value)
            self = .ldi(meta, register, value)
            
        case .push:
            let meta = try container.decodeIfPresent(InstrMeta.self, forKey: .meta)
            let value = try container.decode(ChipCadeData.self, forKey: .value)
            self = .push(meta, value)
            
        case .nop:
            let meta = try container.decodeIfPresent(InstrMeta.self, forKey: .meta)
            self = .nop(meta)
        }
    }
    
    func format() -> String {
        switch self {
        case .ldi(_, let register, let value):
            return "LDI \(register) \(value.toString())"
            
        case .push(_, let value):
            return "PUSH \(value.toString())"
            
        case .nop:
            return "NOP"
        }
    }
    
    func toString() -> String {
        switch self {
        case .ldi(_, _, _):
            return "LDI"
            
        case .push(_, _):
            return "PUSH"
            
        case .nop:
            return "NOP"
        }
    }
}
