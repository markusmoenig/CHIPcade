//
//  Instruction.swift
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//

import SwiftUI

public enum InstructionType: String, Codable, CaseIterable {
    case add
    case brkpt
    case cmp
    case call
    case calltm
    case comnt
    case cos
    case dec
    case div
    case fntset
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
    case ldspr
    case lyrcur
    case lyrres
    case lyrvis
    case mod
    case mul
    case nop
    case push
    case rand
    case rect
    case ret
    case sin
    case spracc
    case spralp
    case spranm
    case sprcol
    case sprhlt
    case sprfps
    case sprfri
    case sprgrp
    case sprimg
    case sprlyr
    case sprmxs
    case sprpri
    case sprroo
    case sprrot
    case sprscl
    case sprset
    case sprspd
    case spract
    case sprwrp
    case sprstp
    case sprx
    case spry
    case st
    case sub
    case tag
    case time
    case txtmem
    case txtval
    
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

    @Published var resolveObject: Bool? = nil

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
        case resolveObject
    }
    
    init(_ type: InstructionType) {
        self.type = type
        
        switch type {
        
        case .cmp:
            value = .unsigned16Bit(0)
        case .add, .sub, .mul, .div, .mod, .sin, .cos:
            register1 = 0
            value = .unsigned16Bit(0)
        case .inc, .dec, .sprstp, .sprhlt:
            register1 = 0
        case .comnt:
            memory = ""
        case .call, .j, .je, .jne, .jl, .jg, .jc, .jo:
            memory = "Module.Tag"
        case .calltm:
            memory = "Module.Tag"
            value = .unsigned16Bit(0)
        case .fntset:
            memory = "Square"
            value = .unsigned16Bit(14)
        case .ld:
            register1 = 0
            memory = "Data"
            memoryOffset = 0
        case .ldi, .sprcol, .sprgrp, .sprfri, .spracc, .sprroo, .sprrot, .sprspd, .spract, .sprx, .spry, .sprwrp, .sprimg, .sprmxs, .sprpri, .spralp, .sprscl:
            register1 = 0
            value = .unsigned16Bit(0)
        case .rand:
            register1 = 0
            value = .unsigned16Bit(10)
        case .sprfps:
            register1 = 0
            value = .unsigned16Bit(10)
        case .ldresx, .ldresy, .time:
            register1 = 0
        case .lyrcur:
            register1 = 0
        case .lyrres:
            register1 = 0
            memory = "320 200"
        case .lyrvis, .sprlyr:
            register1 = 0
            value = .unsigned16Bit(0)
        case .ldspr:
            register1 = 0
            register2 = 0
            memory = "x"
        case .sprset:
            register1 = 0
            memory = "Image Group"
        case .st:
            register1 = 0
            memory = "Data"
            memoryOffset = 0
            value = .unsigned16Bit(0)
        case .spranm:
            register1 = 0
            register2 = 0
            register3 = 0
        case .tag:
            memory = "Tag"
        case .txtmem:
            memory = "Data"
            memoryOffset = 0
        case .txtval:
            value = .unsigned16Bit(0)
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
        try container.encodeIfPresent(resolveObject, forKey: .resolveObject)
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
        resolveObject = try container.decodeIfPresent(Bool.self, forKey: .resolveObject)

//        switch type{
//        case .ldspr:
//            print("load \(memory)")
//        default: break
//        }
    }
    
    func format() -> String {
        switch type {
        case .add:
            return "ADD R\(register1!) \(value!.toString())"
           
        case .brkpt:
            return "BRKPT"
            
        case .cmp:
            return "CMP R\(register1!) \(value!.toString())"
         
        case .call:
            return "CALL \(memory!)"
       
        case .calltm:
            return "CALLTM \(memory!) \(value!.toString())"
            
        case .cos:
            return "COS R\(register1!) \(value!.toString())"
            
        case .comnt:
            return "# \(memory!)"
            
        case .dec:
            return "DEC R\(register1!)"
            
        case .div:
            return "DIV R\(register1!) \(value!.toString())"
          
        case .fntset:
            return "FNTSET \"\(memory!)\" \(value!.toString())"
            
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
       
        case .ldspr:
            return "LDSPR R\(register1!) S\(register2!) \"\(memory!)\""
            
        case .ldresy:
            return "LDRESY R\(register1!)"
            
        case .lyrcur:
            return "LYRCUR \(resolveObject == true ? "R" : "L")\(register1!)"
            
        case .lyrres:
            return "LYRRES \(resolveObject == true ? "R" : "L")\(register1!) \(memory!)"
            
        case .lyrvis:
            return "LYRVIS \(resolveObject == true ? "R" : "L")\(register1!) \(value!.toString())"
            
        case .mod:
            return "MOD R\(register1!) \(value!.toString())"
            
        case .mul:
            return "MUL R\(register1!) \(value!.toString())"
            
        // In code editor, NOPs are empty lines
        case .nop:
            return "" //"NOP"
            
        case .push:
            return "PUSH \(value!.toString())"
            
        case .rand:
            return "RAND R\(register1!) \(value!.toString())"
            
        case .rect:
            return "RECT"
            
        case .ret:
            return "RET"
        
        case .sin:
            return "SIN R\(register1!) \(value!.toString())"
            
        case .st:
            return "ST \(memory!) + \(memoryOffset!) \(value!.toString())"
            
        case .sub:
            return "SUB R\(register1!) \(value!.toString())"
          
        case .spracc:
            return "SPRACC \(resolveObject == true ? "R" : "S")\(register1!) \(value!.toString())"
      
        case .spralp:
            return "SPRALP \(resolveObject == true ? "R" : "S")\(register1!) \(value!.toString())"
            
        case .spranm:
            return "SPRANM \(resolveObject == true ? "R" : "S")\(register1!) \(register2!) \(register3!)"
            
        case .sprcol:
            return "SPRCOL \(resolveObject == true ? "R" : "S")\(register1!) \(value!.toString())"
            
        case .sprfps:
            return "SPRFPS \(resolveObject == true ? "R" : "S")\(register1!) \(value!.toString())"
            
        case .sprfri:
            return "SPRFRI \(resolveObject == true ? "R" : "S")\(register1!) \(value!.toString())"
           
        case .sprhlt:
            return "SPRHLT \(resolveObject == true ? "R" : "S")\(register1!)"
            
        case .sprgrp:
            return "SPRGRP \(resolveObject == true ? "R" : "S")\(register1!) \(value!.toString())"
            
        case .sprimg:
            return "SPRIMG \(resolveObject == true ? "R" : "S")\(register1!) \(value!.toString())"
            
        case .sprlyr:
            return "SPRLYR \(resolveObject == true ? "R" : "S")\(register1!) L\(register2!)"
            
        case .sprmxs:
            return "SPRMXS \(resolveObject == true ? "R" : "S")\(register1!) \(value!.toString())"
          
        case .sprpri:
            return "SPRPRI \(resolveObject == true ? "R" : "S")\(register1!) \(value!.toString())"
         
        case .sprroo:
            return "SPRROO \(resolveObject == true ? "R" : "S")\(register1!) \(value!.toString())"
            
        case .sprrot:
            return "SPRROT \(resolveObject == true ? "R" : "S")\(register1!) \(value!.toString())"
            
        case .sprset:
            return "SPRSET \(resolveObject == true ? "R" : "S")\(register1!) \"\(memory!)\""
            
        case .sprscl:
            return "SPRSCL \(resolveObject == true ? "R" : "S")\(register1!) \(value!.toString())"
            
        case .sprspd:
            return "SPRSPD \(resolveObject == true ? "R" : "S")\(register1!) \(value!.toString())"
            
        case .sprstp:
            return "SPRSTP \(resolveObject == true ? "R" : "S")\(register1!)"
            
        case .spract:
            return "SPRACT \(resolveObject == true ? "R" : "S")\(register1!) \(value!.toString())"
            
        case .sprx:
            return "SPRX \(resolveObject == true ? "R" : "S")\(register1!) \(value!.toString())"
            
        case .spry:
            return "SPRY \(resolveObject == true ? "R" : "S")\(register1!) \(value!.toString())"
            
        case .sprwrp:
            return "SPRWRP \(resolveObject == true ? "R" : "S")\(register1!) \(value!.toString())"
            
        case .tag:
            return "\(memory!):"
        
        case .time:
            return "TIME R\(register1!)"
            
        case .txtmem:
            return "TXTMEM \(memory!) + \(memoryOffset!)"
        
        case .txtval:
            return "TXTVAL \(value!.toString())"
        }
    }
    
    func syntax() -> String {
        switch type {
        case .add:
            return "ADD Rd (Value|Rs)"
         
        case .brkpt:
            return "BRKPT"
            
        case .cos:
            return "COS Rd (Value|Rs)"
            
        case .cmp:
            return "CMP Rd (Value|Rs)"
         
        case .call:
            return "CALL [Module.]Tag"
       
        case .calltm:
            return "CALLTM [Module.]Tag (Value|Rs)"
            
        case .comnt:
            return "# Text"
            
        case .dec:
            return "DEC Rd"
            
        case .div:
            return "DIV Rd (Value|Rs)"
            
        case .fntset:
            return "FNTSET Font (Value|Rs)"
            
        case .inc:
            return "INC Rd"
        
        case .j:
            return "J [Module.]Tag"
            
        case .je:
            return "JE [Module.]Tag"

        case .jne:
            return "JNE [Module.]Tag"
            
        case .jl:
            return "JL [Module.]Tag"
            
        case .jg:
            return "JG [Module.]Tag"
            
        case .jc:
            return "JC [Module.]Tag"
            
        case .jo:
            return "JO [Module.]Tag"
            
        case .ld:
            return "LD Rd Memory + (Value|Rs)"
            
        case .ldi:
            return "LDI Rd (Value|Rs)"

        case .ldresx:
            return "LDRESX Rd"
            
        case .ldresy:
            return "LDRESY Rd"
            
        case .ldspr:
            return "LDSPR Rd Ss Attribute"
          
        case .lyrcur:
            return "LYRCUR (Ld|Rs)"
            
        case .lyrres:
            return "LYRRES (Ld|Rs) Width Height"
            
        case .lyrvis:
            return "LYRVIS (Ld|Rs) (Value|Rs)"
            
        case .mod:
            return "MOD Rd (Value|Rs)"
            
        case .mul:
            return "MUL Rd (Value|Rs)"
            
        case .nop:
            return "NOP"
            
        case .push:
            return "PUSH (Value|Rs)"
            
        case .rand:
            return "RAND Rd (Value|Rs)"
            
        case .rect:
            return "RECT"
            
        case .ret:
            return "RET"
        
        case .sin:
            return "SIN Rd (Value|Rs)"
            
        case .st:
            return "ST Memory + (Value|Rs) (Value|Rs)"
            
        case .sub:
            return "SUB Rd (Value|Rs)"
          
        case .spracc:
            return "SPRACC (Sd|Rs) (Value|Rs)"
      
        case .spralp:
            return "SPRALP (Sd|Rs) (Value|Rs)"
            
        case .spranm:
            return "SPRANM (Sd|Rs) (Value|Rs) (Value|Rs)"
            
        case .sprcol:
            return "SPRCOL (Sd|Rs) (Value|Rs)"
            
        case .sprfps:
            return "SPRFPS (Sd|Rs) (Value|Rs)"
            
        case .sprfri:
            return "SPRFRI (Sd|Rs) (Value|Rs)"
            
        case .sprhlt:
            return "SPRHLT (Sd|Rs)"
            
        case .sprgrp:
            return "SPRGRP (Sd|Rs) (Value|Rs)"
            
        case .sprimg:
            return "SPRIMG (Sd|Rs) (Value|Rs)"
            
        case .sprlyr:
            return "SPRLYR (Sd|Rs) Ls"
            
        case .sprmxs:
            return "SPRMXS (Sd|Rs) (Value|Rs)"
          
        case .sprpri:
            return "SPRPRI (Sd|Rs) (Value|Rs)"
            
        case .sprroo:
            return "SPRROO (Sd|Rs) (Value|Rs)"
            
        case .sprrot:
            return "SPRROT (Sd|Rs) (Value|Rs)"
            
        case .sprset:
            return "SPRSET (Sd|Rs) ImageGroup"
            
        case .sprscl:
            return "SPRSCL (Sd|Rs) (Value|Rs)"
            
        case .sprspd:
            return "SPRSPD (Sd|Rs) (Value|Rs)"
            
        case .sprstp:
            return "SPRSTP (Sd|Rs)"
            
        case .spract:
            return "SPRACT (Sd|Rs) (Value|Rs)"
            
        case .sprx:
            return "SPRX (Sd|Rs) (Value|Rs)"
            
        case .spry:
            return "SPRY (Sd|Rs) (Value|Rs)"
            
        case .sprwrp:
            return "SPRWRP (Sd|Rs) (Value|Rs)"
            
        case .tag:
            return "Tag:"
            
        case .time:
            return "TIME Rd"
            
        case .txtmem:
            return "TXTMEM Memory + (Value|Rs)"

        case .txtval:
            return "TXTVAL (Value|Rs)"
        }
    }
    
    func description() -> String {
        switch type {
        case .add:
            return "Add value to destination register."
        case .brkpt:
            return "Breakpoint. Stops execution for debugging."
        case .cos:
            return "Store the cosine of the value to destination register."
        case .cmp:
            return "Compare two values."
        case .call:
            return "Call a subroutine."
        case .calltm:
            return "Call a subroutine after a specified delay (in seconds)."
        case .comnt:
            return "Comment"
        case .dec:
            return "Decrement register by 1."
        case .div:
            return "Divide destination by source register."
        case .fntset:
            return "Set the current font and size."
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
        case .ldspr:
            return "Load a sprite attribute into register."
        case .lyrcur:
            return "Set the current layer for draw commands."
        case .lyrres:
            return "Set the layer resolution."
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
        case .rand:
            return "Create a random value between 0 and max value."
        case .rect:
            return "Draw rectangle: R0=X, R1=Y, R2=Width, R3=Height, R4=Palette."
        case .sin:
            return "Store the sine of the value to destination register."
        case .st:
            return "Store register to memory."
        case .sub:
            return "Subtract source from destination register."
        case .spracc:
            return "Applies an acceleration impulse."
        case .spralp:
            return "Set the alpha value for the sprite."
        case .spranm:
            return "Set the animation range for the sprite."
        case .sprcol:
            return "Set the ZF to 0 if the sprite collides with the given group, 1 otherwise."
        case .sprfps:
            return "Set the frames per second for the sprite's animation."
        case .sprfri:
            return "Set sprite friction."
        case .sprhlt:
            return "Set sprite velocity to zero. Halt!"
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
        case .sprroo:
            return "Set sprite rotation offset."
        case .sprrot:
            return "Set sprite rotation."
        case .sprset:
            return "Set image group for sprite."
        case .sprscl:
            return "Set sprite alpha value."
        case .sprspd:
            return "Set sprite speed."
        case .sprstp:
            return "Make sprite invisible afer animation finishes."
        case .spract:
            return "Activate / deactivate the sprite."
        case .sprx:
            return "Set sprite x position."
        case .spry:
            return "Set sprite y position."
        case .sprwrp:
            return "Set sprite wrapping mode."
        case .tag:
            return "Set a code tag for conditional execution."
        case .time:
            return "Load the elpased time into the register (in seconds)."
        case .txtmem:
            return "Draw the text or value at the memory address. R0 = X, R1 = Y, R2 = ColorIndex."
        case .txtval:
            return "Draw the value as text. R0 = X, R1 = Y, R2 = ColorIndex."
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
        case .st, .calltm:
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
        case .rect, .sprset, .spract, .sprx, .spry, .lyrres, .lyrvis, .sprrot, .sprwrp, .sprimg, .spracc, .sprmxs, .sprfri, .sprpri, .sprlyr, .sprcol, .sprgrp, .spranm, .sprfps, .sprstp, .sprhlt, .spralp, .sprscl, .lyrcur:
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
