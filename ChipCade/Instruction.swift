//
//  Instruction.swift
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//

import SwiftUI

public enum InstructionType: String, Codable, CaseIterable {
    case add
    case cmp
    case call
    case comnt
    case dec
    case div
    case inc
    case j
    case je
    case jne
    case jl
    case jg
    case jc
    case jo
    case ld
    case ldi
    case ldresx
    case ldresy
    case lyrres
    case lyrvis
    case mod
    case mul
    case nop
    case push
    case rect
    case ret
    case spracc
    case spranm
    case sprcol
    case sprfps
    case sprfri
    case sprgrp
    case sprimg
    case sprlyr
    case sprmxs
    case sprpri
    case sprrot
    case sprset
    case sprspd
    case sprvis
    case sprwrp
    case sprx
    case spry
    case st
    case sub
    case tag
    
    static func fromString(_ string: String) -> InstructionType? {
        if string.starts(with: "#") {
            return .comnt
        }
        return InstructionType.allCases.first { $0.toString().lowercased() == string.lowercased() }
    }
    
    func toString() -> String {
        return self.rawValue.uppercased()
    }
}

public class Instruction: ObservableObject, Codable, Equatable {
    
    var id: UUID = UUID()
    
    @Published var type: InstructionType

    @Published var register1: UInt8? = nil
    @Published var register2: UInt8? = nil
    @Published var register3: UInt8? = nil
    @Published var value: ChipCadeData? = nil

    @Published var memory: String? = nil
    @Published var memoryOffset: Int? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case register1
        case register2
        case register3
        case value
        case memory
        case memoryOffset
    }
    
    init(_ type: InstructionType) {
        self.type = type
        
        switch type {
        
        case .cmp, .add, .sub, .mul, .div, .mod:
            register1 = 0
            register2 = 1
        case .inc, .dec:
            register1 = 0
        case .comnt:
            memory = ""
        case .call, .j, .je, .jne, .jl, .jg, .jc, .jo:
            memory = "Module.Tag"
        case .ld:
            register1 = 0
            memory = "Data"
            memoryOffset = 0
        case .ldi, .sprcol, .sprgrp:
            register1 = 0
            value = .unsigned16Bit(0)
        case .sprfps:
            register1 = 0
            value = .unsigned16Bit(10)
        case .ldresx, .ldresy:
            register1 = 0
        case .lyrres:
            register1 = 0
            memory = "320x200"
        case .lyrvis:
            register1 = 0
            register2 = 0
        case .sprset:
            register1 = 0
            memory = "Image Group"
        case .st:
            register1 = 0
            memory = "Data"
            memoryOffset = 0
        case .spracc, .sprlyr, .sprrot, .sprspd, .sprvis, .sprx, .spry, .sprwrp, .sprimg, .sprmxs, .sprfri, .sprpri:
            register1 = 0
            register2 = 0
        case .spranm:
            register1 = 0
            register2 = 0
            register3 = 0
        case .tag:
            memory = "Tag"
        default: break
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(register1, forKey: .register1)
        try container.encodeIfPresent(register2, forKey: .register2)
        try container.encodeIfPresent(register3, forKey: .register3)
        try container.encodeIfPresent(value, forKey: .value)
        try container.encodeIfPresent(memory, forKey: .memory)
        try container.encodeIfPresent(memoryOffset, forKey: .memoryOffset)
    }
    
    // Decoding
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(InstructionType.self, forKey: .type)  // Correctly decode the enum type
        register1 = try container.decodeIfPresent(UInt8.self, forKey: .register1)
        register2 = try container.decodeIfPresent(UInt8.self, forKey: .register2)
        register3 = try container.decodeIfPresent(UInt8.self, forKey: .register3)
        value = try container.decodeIfPresent(ChipCadeData.self, forKey: .value)
        memory = try container.decodeIfPresent(String.self, forKey: .memory)
        memoryOffset = try container.decodeIfPresent(Int.self, forKey: .memoryOffset)
    }
    
    func format() -> String {
        switch type {
        case .add:
            return "ADD R\(register1!), R\(register2!)"
            
        case .cmp:
            return "CMP R\(register1!), R\(register2!)"
         
        case .call:
            return "CALL"
            
        case .comnt:
            return "# \(memory!)"
            
        case .dec:
            return "DEC R\(register1!)"
            
        case .div:
            return "DIV R\(register1!), R\(register2!)"
            
        case .inc:
            return "INC R\(register1!)"
        
        case .j:
            return "J \(memory!)"
            
        case .je:
            return "JE \(memory!)"

        case .jne:
            return "JNE \(memory!)"
            
        case .jl:
            return "JL \(memory!)"
            
        case .jg:
            return "JG \(memory!)"
            
        case .jc:
            return "JC \(memory!)"
            
        case .jo:
            return "JO \(memory!)"
            
        case .ld:
            return "LD R\(register1!) \(memory!) + \(memoryOffset!)"
            
        case .ldi:
            return "LDI R\(register1!) \(value!.toString())"

        case .ldresx:
            return "LDRESX R\(register1!)"
            
        case .ldresy:
            return "LDRESY R\(register1!)"
            
        case .lyrres:
            return "LYRRES L\(register1!) \(memory!)"
            
        case .lyrvis:
            return "LYRVIS L\(register1!) \(register2!)"
            
        case .mod:
            return "MOD R\(register1!), R\(register2!)"
            
        case .mul:
            return "MUL R\(register1!), R\(register2!)"
            
        case .nop:
            return "NOP"
            
        case .push:
            return "PUSH \(value!.toString())"
            
        case .rect:
            return "RECT"
            
        case .ret:
            return "RET"
            
        case .sprset:
            return "SPRSET S\(register1!) \(memory!)"
        
        case .st:
            return "ST \(memory!) + \(memoryOffset!) R\(register1!)"
            
        case .sub:
            return "SUB R\(register1!), R\(register2!)"
          
        case .spracc:
            return "SPRACC S\(register1!) L\(register2!)"
      
        case .spranm:
            return "SPRANM S\(register1!) \(register2!) \(register2!)"
            
        case .sprcol:
            return "SPRCOL S\(register1!) \(value!.toString())"
            
        case .sprfps:
            return "SPRFPS S\(register1!) \(value!.toString())"
            
        case .sprfri:
            return "SPRFRI S\(register1!) L\(register2!)"
            
        case .sprgrp:
            return "SPRGRP S\(register1!) \(value!.toString())"
            
        case .sprimg:
            return "SPRIMG S\(register1!) R\(register2!)"
            
        case .sprlyr:
            return "SPRLYR S\(register1!) L\(register2!)"
            
        case .sprmxs:
            return "SPRMXS S\(register1!) L\(register2!)"
          
        case .sprpri:
            return "SPRPRI S\(register1!) L\(register2!)"
            
        case .sprrot:
            return "SPRROT S\(register1!) R\(register2!)"
            
        case .sprspd:
            return "SPRSPD S\(register1!) R\(register2!)"
            
        case .sprvis:
            return "SPRVIS S\(register1!) \(register2!)"
            
        case .sprx:
            return "SPRX S\(register1!) R\(register2!)"
            
        case .spry:
            return "SPRY S\(register1!) R\(register2!)"
            
        case .sprwrp:
            return "SPRWRP S\(register1!) \(register2!)"
            
        case .tag:
            return "\(memory!):"
        }
    }
    
    func description() -> String {
        switch type {
        case .add:
            return "Add source to destination register."
        case .cmp:
            return "Compare two registers."
        case .call:
            return "Call a subroutine."
        case .comnt:
            return "Comment"
        case .dec:
            return "Decrement register by 1."
        case .div:
            return "Divide destination by source register."
        case .inc:
            return "Increment register by 1."
        case .j:
            return "Unconditional jump."
        case .je:
            return "Jump if the zero flag is set (equality check)."
        case .jne:
            return "Jump if the zero flag is not set (inequality check)."
        case .jl:
            return "Jump if the negative flag is set (less than)."
        case .jg:
            return "Jump if the zero flag is clear and the negative flag is clear (greater than)."
        case .jc:
            return "Jump if the carry flag is set (used for unsigned comparisons)."
        case .jo:
            return "Jump if the overflow flag is set (used for signed overflows)."
        case .ld:
            return "Load memory into register."
        case .ldi:
            return "Load immediate value into register."
        case .ldresx:
            return "Load resolution x value into register."
        case .ldresy:
            return "Load resolution y value into register."
        case .lyrres:
            return "Set the layer resolution (WidthxHeight)."
        case .lyrvis:
            return "Set the layer visibility."
        case .mod:
            return "Modulus of destination by source register."
        case .mul:
            return "Multiply source with destination register."
        case .nop:
            return "No operation."
        case .push:
            return "Push register to stack."
        case .ret:
            return "Return from subroutine."
        case .rect:
            return "Draw rectangle: R0=X, R1=Y, R2=Width, R3=Height, R4=Palette."
        case .sprset:
            return "Set image group for sprite."
        case .st:
            return "Store register to memory."
        case .sub:
            return "Subtract source from destination register."
        case .spracc:
            return "Applies an acceleration impulse."
        case .spranm:
            return "Set the animation range for the sprite."
        case .sprcol:
            return "Set the ZF to 0 if the sprite collides with the given group, 1 otherwise."
        case .sprfps:
            return "Set the frames per second for the sprite's animation."
        case .sprfri:
            return "Set sprite friction."
        case .sprgrp:
            return "Assigns the sprite to the given collision group."
        case .sprimg:
            return "Set the image index for the sprite."
        case .sprlyr:
            return "Set sprite layer."
        case .sprmxs:
            return "Set sprite maximum speed."
        case .sprpri:
            return "Set sprite priority."
        case .sprrot:
            return "Set sprite rotation."
        case .sprspd:
            return "Set sprite speed."
        case .sprvis:
            return "Set sprite visibility."
        case .sprx:
            return "Set sprite x position."
        case .spry:
            return "Set sprite y position."
        case .sprwrp:
            return "Set sprite wrapping mode."
        case .tag:
            return "Set a code tag for conditional execution."
        }
    }
    
    func toString() -> String {
        self.type.toString()
    }
    
    func registers() -> (UInt8?, [UInt8]) {
        var dest : UInt8? = nil
        var source : [UInt8] = []
        
        switch type {
        case .cmp:
            dest = register1!
            source = [register2!]
        case .ldi, .ld, .dec, .inc, .ldresx, .ldresy:
            dest = register1!
        case .rect:
            source = [0, 1, 2, 3, 4]
        case .st:
            source = [register1!]
        case .sprset:
            source = [register1!]
        case .spracc, .sprx, .spry, .sprrot, .sprspd, .sprimg, .sprfri, .sprmxs, .sprpri:
            source = [register2!]
        default: break;
        }
        
        return (dest, source)
    }
    
    func color() -> Color {
        switch type {
        case .tag: return .blue
        case .comnt: return .secondary
        case .rect, .sprset,.sprvis, .sprx, .spry, .lyrres, .lyrvis, .sprrot, .sprwrp, .sprimg, .spracc, .sprmxs, .sprfri, .sprpri, .sprlyr, .sprcol, .sprgrp, .spranm, .sprfps:
            return .yellow
        default:
            return .primary
        }
    }
    
    func clone() -> Instruction {
        let clonedInstruction = Instruction(self.type)
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
