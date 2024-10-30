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
        
        let instruction = Instruction(type)
        
        switch type {
        case .add, .cmp, .sub, .mul, .div, .mod:
            // XXX Rd Rs
            if components.count == 3,
               let reg1 = parseRegister(components[1]),
               let reg2 = parseRegister(components[2]) {
                instruction.register1 = reg1
                instruction.register2 = reg2
            } else {
                return nil
            }

        case .inc, .dec:
            // INC R0
            if components.count == 2,
               let reg1 = parseRegister(components[1]) {
                instruction.register1 = reg1
            } else {
                return nil
            }

        case .ldi:
            // LDI R0 10
            if components.count == 3,
               let reg1 = parseRegister(components[1]),
               let value = ChipCadeData.fromString(components[2]) {
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
                // Join components 3 and 4 to handle spaces
                let offsetString = components[3...].joined().replacingOccurrences(of: " ", with: "")

                // Match "+N" where N is the offset
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

        case .lyrvis:
            // LYRVIS L0 0
            //print("\(components) \(parseRegister(components[1])) \(parseData(components[2]))")
            if components.count == 3,
               let reg1 = parseRegister(components[1]),
               let reg2 = UInt8(components[2]) {
                instruction.register1 = reg1
                instruction.register2 = reg2
            } else {
                return nil
            }
            
        case .sprvis, .sprwrp:
            // SPRVIS S0 0
            if components.count == 3,
               let reg1 = parseRegister(components[1]),
               let reg2 = UInt8(components[2]) {
                instruction.register1 = reg1
                instruction.register2 = reg2
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
            if components.count == 4 {
                // Handle "ST Data +1 R0" or "ST Data + 1 R0"
                let offsetString = components[2].trimmingCharacters(in: .whitespaces)
                if offsetString.starts(with: "+"),
                   let offsetValue = Int(offsetString.dropFirst()) {
                    offset = offsetValue
                } else {
                    return nil // Invalid offset
                }
            }

            // Parse the register (last component)
            guard let reg1 = parseRegister(components.last!) else {
                return nil // Invalid register
            }

            instruction.register1 = reg1
            instruction.memory = memory
            instruction.memoryOffset = offset

        case .sprset:
            // SPRSET S0 ImageGroup
            if components.count == 3,
               let reg1 = parseRegister(components[1]) {
                instruction.register1 = reg1
                instruction.memory = components[2]
            } else {
                return nil
            }

        case .spracc, .sprlyr, .sprrot, .sprspd, .sprx, .spry, .sprimg, .sprmxs, .sprfri, .sprpri:
            // XXXXXX Sd Rs
            if components.count == 3,
               let reg1 = parseRegister(components[1]),
               let reg2 = parseRegister(components[2]) {
                instruction.register1 = reg1
                instruction.register2 = reg2
            } else {
                return nil
            }

        case .spranm:
            // XXXXXX Sd From To
            if components.count == 4,
               let reg1 = parseRegister(components[1]),
               let reg2 = UInt8(components[2]),
               let reg3 = UInt8(components[3]) {
                instruction.register1 = reg1
                instruction.register2 = reg2
                instruction.register3 = reg3
            } else {
                return nil
            }
            
        case .sprcol, .sprgrp, .sprfps:
            // XXXXXX Sd Value
            if components.count == 3,
               let reg1 = parseRegister(components[1]),
               let value = ChipCadeData.fromString(components[2]) {
                instruction.register1 = reg1
                instruction.value = value
            } else {
                return nil
            }

        case .push:
            // PUSH 10
            if components.count == 2,
               let value = ChipCadeData.fromString(components[1]) {
                instruction.value = value
            }

        case .nop, .ret:
            // NOP, RET (No additional components expected)
            break

        case .comnt:
            // COMNT (Everything after '#' is a comment)
            if let comment = string.split(separator: "#").last {
                instruction.memory = String(comment)
            }

        default:
            return nil
        }
        
        return instruction
    }

    private static func parseData(_ component: String) -> ChipCadeData? {
        if let data = ChipCadeData.fromString(component) {
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
