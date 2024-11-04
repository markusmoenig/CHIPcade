//
//  InstructionFromString.swift
//  CHIPcade
//
//  Created by Markus Moenig on 29/10/24.
//

extension Instruction {
    static func fromString(_ string: String) -> Instruction? {
        let components = string.split(separator: " ").map { String($0) }
        
        guard let firstComponent = components.first else { return nil }
        guard let type = InstructionType.fromString(firstComponent) else { return nil }
        
        Game.shared.errorInstructionType = type
        
        let instruction = Instruction(type)
        
        switch type {
        case .inc, .dec, .sprstp:
            // XXXXXX Rd
            if components.count == 2,
               let reg1 = parseRegister(components[1]) {
                instruction.register1 = reg1
            } else {
                return nil
            }

        case .ldi, .cmp, .add, .sub, .mul, .div, .mod:
            // XXXXXX Rd Value
            if components.count == 3,
               let reg1 = parseRegister(components[1]),
               let value = ChipCadeData.fromString(text: components[2], unsignedDefault: true) {
                instruction.register1 = reg1
                instruction.value = value
            } else {
                return nil
            }

        case .ld:
            // Ensure we have at least 3 components: "LD R0 Data"
            guard components.count >= 3 else { return nil }

            // Parse the register
            guard let reg1 = parseRegister(components[1]) else {
                return nil // Invalid register
            }
            
            // Extract memory part
            let memory = String(components[2])
            var offset = 0

            // Handle offset variations: "LD R0 Data", "LD R0 Data +10", "LD R0 Data + 10"
            if components.count >= 4 {
                // Join offset components, removing any spaces, to handle cases like "+ 10"
                let offsetString = components[3...].joined().replacingOccurrences(of: " ", with: "")

                // Check for and parse "+N" where N is the offset
                if offsetString.starts(with: "+"),
                   let offsetValue = Int(offsetString.dropFirst()) {
                    offset = offsetValue
                } else {
                    return nil // Invalid offset
                }
            }

            instruction.register1 = reg1
            instruction.memory = memory
            instruction.memoryOffset = offset

        case .j, .je, .jne, .jl, .jg, .jc, .jo, .call:
            // J Module.Tag
            if components.count == 2 {
                instruction.memory = components[1]
            } else {
                return nil
            }

        case .rect:
            // RECT (No additional components expected)
            break

        case .lyrres:
            // LYRRES L0 320 200
            if components.count == 4,
               let reg1 = parseRegister(components[1]) {
                instruction.register1 = reg1
                instruction.memory = "\(components[2]) \(components[3])"
            } else {
                return nil
            }

        case .st:
            // Ensure we have at least 3 components: "ST Data R0"
            guard components.count >= 3 else { return nil }

            // Extract memory part
            let memory = String(components[1])
            var offset = 0

            // Handle offset variations: "ST Data R0", "ST Data +1 R0", "ST Data + 1 R0"
            if components.count == 4 || components.count == 5 {
                // Join the "+" and offset number if separated by a space
                let offsetPart = components[2...components.count - 2].joined(separator: " ").trimmingCharacters(in: .whitespaces)
                
                if offsetPart.starts(with: "+"), let offsetValue = Int(offsetPart.dropFirst().trimmingCharacters(in: .whitespaces)) {
                    offset = offsetValue
                } else {
                    return nil // Invalid offset format
                }
            }
            
            // Parse the register (last component)
                guard let value = ChipCadeData.fromString(text: components.last!, unsignedDefault: true) else {
                return nil // Invalid register
            }

            instruction.value = value
            instruction.memory = memory
            instruction.memoryOffset = offset

        case .sprset:
            // SPRSET S0 ImageGroup
            if components.count == 3,
               let reg1 = parseRegister(components[1]) {
                instruction.register1 = reg1
                instruction.memory = components[2].replacingOccurrences(of: "\"", with: "")
            } else {
                return nil
            }

        case .sprlyr:
            // XXXXXX Sd Rs
            if components.count == 3,
               let reg1 = parseRegister(components[1]),
               let reg2 = parseRegister(components[2]) {
                instruction.register1 = reg1
                instruction.register2 = reg2
            } else {
                return nil
            }
            
        case .spracc, .sprrot, .sprspd, .sprx, .spry, .sprimg, .sprmxs, .sprpri, .sprvis, .sprwrp:
            // XXXXXX Sd Rs
            if components.count == 3,
               let reg1 = parseRegister(components[1]),
               let value = ChipCadeData.fromString(text: components[2], unsignedDefault: true) {
                instruction.register1 = reg1
                instruction.value = value
            } else {
                return nil
            }
            
        case .lyrvis:
            // LYRVIS L0 0
            if components.count == 3,
               let reg1 = parseRegister(components[1]),
               let value = ChipCadeData.fromString(text: components[2], unsignedDefault: true) {
                instruction.register1 = reg1
                instruction.value = value
            } else {
                return nil
            }

        case .spranm:
            // XXXXXX Sd From To
            if components.count == 4,
               let reg1 = parseRegister(components[1]),
               let reg2 = ChipCadeData.fromString(text: components[2], unsignedDefault: true),
               let reg3 = ChipCadeData.fromString(text: components[3], unsignedDefault: true) {
                instruction.register1 = reg1
                instruction.register2 = UInt8(reg2.toInt32Bit())
                instruction.register3 = UInt8(reg3.toInt32Bit())
            } else {
                return nil
            }
            
        case .sprcol, .sprgrp, .sprfps, .rand, .sprfri:
            // XXXXXX Sd Value
            if components.count == 3,
               let reg1 = parseRegister(components[1]),
               let value = ChipCadeData.fromString(text: components[2], unsignedDefault: true) {
                instruction.register1 = reg1
                instruction.value = value
            } else {
                return nil
            }
            
        case .calltm:
            // CALLTM Tag Value
            if components.count == 3,
               let value = ChipCadeData.fromString(text: components[2], unsignedDefault: true) {
                instruction.memory = components[1]
                instruction.value = value
            } else {
                return nil
            }

        case .push:
            // PUSH 10
            if components.count == 2,
               let value = ChipCadeData.fromString(text: components[1], unsignedDefault: true) {
                instruction.value = value
            }

        case .nop, .ret:
            // NOP, RET (No additional components expected)
            break

        case .comnt:
            // COMNT (Everything after '#' is a comment)
            if let comment = string.split(separator: "#").last {
                instruction.memory = String(comment.trimmingCharacters(in: .whitespaces))
            }

        default:
            return nil
        }
        
        Game.shared.errorInstructionType = nil
        
        return instruction
    }

    private static func parseData(_ component: String) -> ChipCadeData? {
        if let data = ChipCadeData.fromString(text: component, unsignedDefault: true) {
            return data
        } else if let value = UInt16(component) {
            return .unsigned16Bit(value)
        }
        return nil
    }
    
    private static func parseRegister(_ component: String) -> UInt8? {
        let component = component.uppercased()
        if component.starts(with: "R"),
           let regNumber = UInt8(component.dropFirst()) {
            return regNumber
        }
        if component.starts(with: "S"),
           let spriteNumber = UInt8(component.dropFirst()) {
            return spriteNumber
        }
        if component.starts(with: "L"),
           let layerNumber = UInt8(component.dropFirst()) {
            return layerNumber
        }
        return nil
    }

    private static func parseMemory(_ components: ArraySlice<String>) -> (String?, Int?) {
        guard let memory = components.first else { return (nil, nil) }
        let offset = components.dropFirst().first { $0.starts(with: "+") }
        let memoryOffset = offset != nil ? Int(offset!.dropFirst()) : nil
        return (memory, memoryOffset)
    }
}
