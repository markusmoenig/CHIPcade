//
//  Instruction.swift
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//

import Foundation

enum Instruction: Codable {
    case push(ChipCadeData)
    case nop

    enum CodingKeys: String, CodingKey {
        case push
        case nop
    }
    

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .push(let value):
            try container.encode(value, forKey: .push)
        case .nop:
            try container.encodeNil(forKey: .nop)
        }
    }
    
    func format() -> String {
        switch self {
        case .push(let value):
            return "PUSH \(value.toString())"
            
        case .nop:
            return "NOP"
        }
    }
}

/*
class Instruction: Hashable, Identifiable {
    var id: UUID  // Unique identifier for the instruction
    var opcode: UInt16
    var operands: [UInt16]

    // Computed property to get the InstructionSet from opcode
    var instructionSet: InstructionSet? {
        get {
            return InstructionSet(rawValue: opcode)
        }
        set {
            if let newSet = newValue {
                opcode = newSet.rawValue
            }
        }
    }
    
    // Method to update the MemoryItem based on current opcode and operands
    func updateMemoryItem(_ memoryItem: inout MemoryItem, at index: Int) {
        // Store the opcode as ChipCadeData
        memoryItem.memory[index] = .unsigned16Bit(opcode)
        
        // Store operands as ChipCadeData
        for i in 0..<operands.count {
            memoryItem.memory[index + 1 + i] = .unsigned16Bit(operands[i])
        }
    }
    
    // Enum representing operand types
    enum OperandType {
        case memoryAddress
        case immediateValue
    }

    // Enum representing the instruction set
    enum InstructionSet: UInt16, CaseIterable {
        case push = 0x0001
        case add = 0x0002
        case nop = 0x0000

        var operandTypes: [OperandType] {
            switch self {
            case .push:
                return [.immediateValue]
            case .add:
                return []
            case .nop:
                return []
            }
        }

        var description: String {
            switch self {
            case .push:
                return "PUSH"
            case .add:
                return "ADD"
            case .nop:
                return "NOP"
            }
        }

        // Function to format the instruction with its operands
        func format(operands: [UInt16]) -> String? {
            switch self {
            case .push:
                guard operands.count == 1 else { return nil }
                return "PUSH \(String(format: "%04X", operands[0])))"
                
            case .add:
                guard operands.count == 0 else { return nil }
                return "ADD"
                
            case .nop:
                return "NOP"
            }
        }

        // Look up an instruction by opcode
        static func instructionInfo(for opcode: UInt16) -> InstructionSet? {
            return InstructionSet(rawValue: opcode)
        }
    }

    init(opcode: UInt16, operands: [UInt16]) {
        self.id = UUID()
        self.opcode = opcode
        self.operands = operands
    }

    // Conformance to Hashable and Identifiable
    static func == (lhs: Instruction, rhs: Instruction) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Convert the instruction to a readable string
    func toString() -> String {
        guard let instructionSet = InstructionSet.instructionInfo(for: opcode) else {
            return "Unknown opcode: \(String(format: "%04X", opcode))"
        }

        // Use nil-coalescing operator to return an error message if formatting fails
        return instructionSet.format(operands: operands) ?? "Invalid instruction or operand count"
    }

    // Decoding the instructions from memory
    static func decodeInstructions(from memory: [ChipCadeData]) -> [Instruction] {
        var instructions: [Instruction] = []
        var index = 0

        while index < memory.count {
            guard let opcode = memory[index].toUInt16() else {
                break  // Invalid opcode or end of memory
            }

            // Try to find the instruction set for this opcode
            guard let instructionSet = InstructionSet(rawValue: opcode) else {
                instructions.append(Instruction(opcode: opcode, operands: []))
                break  // Invalid instruction, move on to the next
            }

            index += 1  // Move past the opcode

            // Get the expected number of operands for the instruction
            let operandCount = instructionSet.operandTypes.count
            var operands: [UInt16] = []

            // Fetch the operands from memory
            for _ in 0..<operandCount {
                if index < memory.count, let operand = memory[index].toUInt16() {
                    operands.append(operand)
                    index += 1  // Move past the operand
                } else {
                    // If we don't have enough operands, append invalid instruction
                    instructions.append(Instruction(opcode: opcode, operands: []))
                    return instructions  // Return with incomplete operands
                }
            }
            
            // Append the instruction with the extracted operands
            instructions.append(Instruction(opcode: opcode, operands: operands))
        }

        return instructions
    }
}

*/
