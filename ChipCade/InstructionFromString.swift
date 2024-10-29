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
            // ADD R0, R1
            if components.count == 3,
               let reg1 = parseRegister(components[1]),
               let reg2 = parseRegister(components[2]) {
                instruction.register1 = reg1
                instruction.register2 = reg2
            }

        case .inc, .dec:
            // INC R0
            if components.count == 2,
               let reg1 = parseRegister(components[1]) {
                instruction.register1 = reg1
            }

        case .ldi:
            // LDI R0 10
            if components.count == 3,
               let reg1 = parseRegister(components[1]),
               let value = ChipCadeData.fromString(components[2]) {
                instruction.register1 = reg1
                instruction.value = value
            }

        case .ld:
            // LD R0 Data + 10
            if components.count >= 3,
               let reg1 = parseRegister(components[1]) {
                let (memory, offset) = parseMemory(components[2...])
                instruction.register1 = reg1
                instruction.memory = memory
                instruction.memoryOffset = offset
            }

        case .j, .je, .jne, .jl, .jg, .jc, .jo, .call:
            // J Module.Tag
            if components.count == 2 {
                instruction.memory = components[1]
            }

        case .rect:
            // RECT (No additional components expected)
            break

        case .lyrres:
            // LYRRES L0 320x200
            if components.count == 3,
               let reg1 = parseRegister(components[1]) {
                instruction.register1 = reg1
                instruction.memory = components[2]
            }

        case .lyrvis:
            // LYRVIS L0 1
            if components.count == 3,
               let reg1 = parseRegister(components[1]),
               let value = ChipCadeData.fromString(components[2]) {
                instruction.register1 = reg1
                instruction.value = value
            }

        case .st:
            // ST Data + 10 R0
            if components.count >= 4,
               let reg1 = parseRegister(components[3]) {
                let (memory, offset) = parseMemory(components[1...2])
                instruction.register1 = reg1
                instruction.memory = memory
                instruction.memoryOffset = offset
            }

        case .sprset:
            // SPRSET S0 ImageGroup
            if components.count == 3,
               let reg1 = parseRegister(components[1]) {
                instruction.register1 = reg1
                instruction.memory = components[2]
            }

        case .spracc, .sprlyr, .sprrot, .sprspd, .sprvis, .sprx, .spry, .sprwrp, .sprimg, .sprmxs, .sprfri, .sprpri:
            // SPRACC S0 L1
            if components.count == 3,
               let reg1 = parseRegister(components[1]),
               let reg2 = parseRegister(components[2]) {
                instruction.register1 = reg1
                instruction.register2 = reg2
            }

        case .sprcol, .sprgrp:
            // SPRCOL S0 10
            if components.count == 3,
               let reg1 = parseRegister(components[1]),
               let value = ChipCadeData.fromString(components[2]) {
                instruction.register1 = reg1
                instruction.value = value
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

        case .tag:
            // TAG (Everything after 'TAG' is a tag)
            if components.count == 2 {
                instruction.memory = components[1]
            }

        default:
            return nil
        }
        
        return instruction
    }

    private static func parseRegister(_ component: String) -> UInt8? {
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
