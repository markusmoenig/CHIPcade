//
//  Instruction.swift
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//

import Foundation

public class InstrMeta : Codable {
    
    @Published var marker: String = ""
    @Published var comment: String = ""
    
    @Published var breakpoint: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case marker
        case comment
        case breakpoint
    }
    
    init() {
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(marker, forKey: .marker)
        try container.encode(comment, forKey: .comment)
        try container.encode(breakpoint, forKey: .breakpoint)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        marker = try container.decode(String.self, forKey: .marker)
        comment = try container.decode(String.self, forKey: .comment)
        breakpoint = try container.decode(Bool.self, forKey: .breakpoint)
    }
    
    func clone() -> InstrMeta {
        let clonedMeta = InstrMeta()
        clonedMeta.comment = self.comment
        clonedMeta.marker = self.marker
        clonedMeta.breakpoint = self.breakpoint
        
        return clonedMeta
    }
}

public enum InstructionType: String, Codable, CaseIterable {
    case dec
    case inc
    case ld
    case ldi
    case push
    case nop
    case rect
    case st
    
    static func fromString(_ string: String) -> InstructionType? {
        return InstructionType.allCases.first { $0.toString().lowercased() == string.lowercased() }
    }
    
    func toString() -> String {
        return self.rawValue.uppercased()
    }
}

public class Instruction: ObservableObject, Codable, Equatable {
    
    var id: UUID = UUID()
    
    @Published var type: InstructionType

    @Published var meta: InstrMeta = InstrMeta()

    @Published var register1: Int8? = nil
    @Published var register2: Int8? = nil
    @Published var value: ChipCadeData? = nil

    @Published var memory: String? = nil
    @Published var memoryOffset: Int? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case meta
        case register1
        case register2
        case value
        case memory
        case memoryOffset
    }
    
    init(_ type: InstructionType) {
        self.type = type
        
        switch type {
        case .inc, .dec:
            register1 = 0
        case .ld:
            register1 = 0
            memory = "Data"
            memoryOffset = 0
        case .st:
            register1 = 0
            memory = "Data"
            memoryOffset = 0
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
        try container.encodeIfPresent(register1, forKey: .register1)
        try container.encodeIfPresent(register2, forKey: .register2)
        try container.encodeIfPresent(value, forKey: .value)
        try container.encodeIfPresent(memory, forKey: .memory)
        try container.encodeIfPresent(memoryOffset, forKey: .memoryOffset)
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
        memory = try container.decodeIfPresent(String.self, forKey: .memory)
        memoryOffset = try container.decodeIfPresent(Int.self, forKey: .memoryOffset)
    }
    
    func format() -> String {
        switch type {
        case .dec:
            return "DEC R\(register1!)"
            
        case .inc:
            return "INC R\(register1!)"
            
        case .ld:
            return "LD R\(register1!) \(memory!) + \(memoryOffset!)"
            
        case .ldi:
            return "LDI R\(register1!) \(value!.toString())"
            
        case .push:
            return "PUSH \(value!.toString())"
            
        case .nop:
            return "NOP"
            
        case .rect:
            return "RECT"
            
        case .st:
            return "ST \(memory!) + \(memoryOffset!) R\(register1!)"
        }
    }
    
    func description() -> String {
        switch type {
        case .dec:
            return "Decreases the register by 1"
        case .inc:
            return "Increases the register by 1"
        case .ld:
            return "Load memory into a register"
        case .ldi:
            return "Load an immediate value into a register"
        case .push:
            return "PUSH"
            
        case .nop:
            return "No operation"
        case .rect:
            return "Draw a rectangle: R0 = X, R1 = Y, R2 = Width, R3 = Height, R4 = Palette Index"
        case .st:
            return "Store to memory from a register"
        }
    }
    
    func toString() -> String {
        self.type.toString()
    }
    
    func registers() -> (Int8?, [Int8]) {
        var dest : Int8? = nil
        var source : [Int8] = []
        
        switch type {
        case .ldi, .ld, .dec, .inc:
            dest = register1!
        case .rect:
            source = [0, 1, 2, 3, 4]
        case .st:
            source = [register1!]
        default: break;
        }
        
        return (dest, source)
    }
    
    /// Returns true if this is an instruction of the GCP
    func isGCP() -> Bool {
        switch type {
        case .rect:
            return true
        default:
            return false
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
        clonedInstruction.memory = self.memory
        clonedInstruction.memoryOffset = self.memoryOffset
        return clonedInstruction
    }
    
    public static func == (lhs: Instruction, rhs: Instruction) -> Bool {
        return lhs.id == rhs.id
    }
}
