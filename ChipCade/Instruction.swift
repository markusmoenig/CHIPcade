//
//  Instruction.swift
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//

import Foundation

public class InstrMeta : Codable {
    
    var comment: String = ""
    var name: String = ""
    
    var breakpoint: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case comment
        case name
        case breakpoint
    }
    
    init() {
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(comment, forKey: .comment)
        try container.encode(name, forKey: .name)
        try container.encode(breakpoint, forKey: .breakpoint)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        comment = try container.decode(String.self, forKey: .comment)
        name = try container.decode(String.self, forKey: .name)
        breakpoint = try container.decode(Bool.self, forKey: .breakpoint)
    }
    
    func clone() -> InstrMeta {
        let clonedMeta = InstrMeta()
        clonedMeta.comment = self.comment
        clonedMeta.name = self.name
        clonedMeta.breakpoint = self.breakpoint
        
        return clonedMeta
    }
}

public enum InstructionType: String, Codable {
    case ldi
    case push
    case nop
    case rect
}

public class Instruction: ObservableObject, Codable, Equatable {
    var id: UUID

    @Published var type: InstructionType

    @Published var meta: InstrMeta = InstrMeta()

    @Published var register1: Int8? = nil
    @Published var register2: Int8? = nil
    @Published var value: ChipCadeData? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case meta
        case register1
        case register2
        case value
    }
    
    init(_ type: InstructionType) {
        id = UUID()
        self.type = type
        
        switch type {
        case .ldi:
            register1 = 0
            value = .unsigned16Bit(0)
        default: break
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(meta, forKey: .meta)
        try container.encode(register1, forKey: .register1)
        try container.encode(register2, forKey: .register2)
        try container.encode(value, forKey: .value)
    }
    
    // Decoding
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(InstructionType.self, forKey: .type)  // Correctly decode the enum type
        meta = try container.decode(InstrMeta.self, forKey: .meta)
        register1 = try container.decodeIfPresent(Int8.self, forKey: .register1)
        register2 = try container.decodeIfPresent(Int8.self, forKey: .register2)
        value = try container.decodeIfPresent(ChipCadeData.self, forKey: .value)
    }
    
    func format() -> String {
        switch type {
        case .ldi:
            return "LDI R\(register1!) \(value!.toString())"
            
        case .push:
            return "PUSH \(value!.toString())"
            
        case .nop:
            return "NOP"
            
        case .rect:
            return "RECT"
        }
    }
    
    func description() -> String {
        switch type {
        case .ldi:
            return "Loads an immediate value into a register"
            
        case .push:
            return "PUSH"
            
        case .nop:
            return "No operation (does nothing)"
        case .rect:
            return "Draws a rectangle: R0 = X, R1 = Y, R2 = Width, R3 = Height, R4 = Palette Index"
        }
    }
    func toString() -> String {
        switch type {
        case .ldi:
            return "LDI"
            
        case .push:
            return "PUSH"
            
        case .nop:
            return "NOP"
            
        case .rect:
            return "RECT"
        }
    }
    
    func clone() -> Instruction {
        let clonedInstruction = Instruction(self.type)
        clonedInstruction.meta = self.meta.clone()
        clonedInstruction.register1 = self.register1
        clonedInstruction.register2 = self.register2
        if let value = value {
            clonedInstruction.value = value.clone()
        }
        return clonedInstruction
    }
    
    public static func == (lhs: Instruction, rhs: Instruction) -> Bool {
        return lhs.id == rhs.id
    }
}
