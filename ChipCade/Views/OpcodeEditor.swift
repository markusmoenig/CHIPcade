//
//  OpcodeEditor.swift
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//

import SwiftUI

/*
struct OpcodeEditorView: View {
    @Binding var selectedInstruction: Instruction
    @Binding var memoryItem: MemoryItem  // Binding to MemoryItem

    var instructionIndex: Int  // The index of the instruction in the memory

    var body: some View {
        VStack(spacing: 20) {
            // Show a menu on tap to change the opcode
            Menu {
                ForEach(Instruction.InstructionSet.allCases, id: \.self) { instruction in
                    Button(action: {
                        // Replace the current instruction with the new one
                        let oldOperandCount = selectedInstruction.operands.count
                        let newOperandCount = instruction.operandTypes.count
                        
                        // Update the selected instruction's opcode
                        selectedInstruction.instructionSet = instruction
                        
                        // Adjust the memory for the new operand count
                        adjustMemoryForOperands(newOperandCount: newOperandCount, oldOperandCount: oldOperandCount)
                        
                        // Update the memory item directly
                        selectedInstruction.updateMemoryItem(&memoryItem, at: instructionIndex)
                    }) {
                        Text(instruction.description)
                    }
                }
            } label: {
                Text(selectedInstruction.instructionSet?.description ?? "Unknown")
                    .font(.headline)
                    .padding()
            }

            // Display operand buttons, dynamically calculated from memory
            ForEach(0..<selectedInstruction.operands.count, id: \.self) { index in
                OperandButtonView(operand: Binding(
                    get: { self.getOperand(at: index) },
                    set: { newValue in self.setOperand(newValue, at: index) }
                ), operandType: selectedInstruction.instructionSet?.operandTypes[index] ?? .memoryAddress)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Methods

    // Dynamically get the operand from memory based on index
    func getOperand(at index: Int) -> UInt16 {
        let operandOffset = instructionIndex + 2 + index * 2  // Opcode takes 2 bytes
        guard let highByte = memoryItem.memory[operandOffset].toUInt8(high: true),
              let lowByte = memoryItem.memory[operandOffset + 1].toUInt8(high: false) else {
            return 0  // Default to 0 if conversion fails
        }
        return (UInt16(highByte) << 8) | UInt16(lowByte)
    }
    
    // Set the operand in memory directly
    func setOperand(_ value: UInt16, at index: Int) {
        let operandOffset = instructionIndex + 2 + index * 2  // Opcode takes 2 bytes
        memoryItem.memory[operandOffset] = .unsigned16Bit(value >> 8)  // High byte
        memoryItem.memory[operandOffset + 1] = .unsigned16Bit(value & 0xFF)  // Low byte
    }
    
    // Adjust memory when operand count changes
    func adjustMemoryForOperands(newOperandCount: Int, oldOperandCount: Int) {
        if newOperandCount > oldOperandCount {
            // Insert extra space for new operands
            for _ in 0..<(newOperandCount - oldOperandCount) {
                memoryItem.memory.insert(.unsigned16Bit(0), at: instructionIndex + 2 + oldOperandCount * 2)
            }
        } else if newOperandCount < oldOperandCount {
            // Remove extra operands
            memoryItem.memory.removeSubrange(instructionIndex + 2 + newOperandCount * 2..<instructionIndex + 2 + oldOperandCount * 2)
        }
    }
}

struct OperandButtonView: View {
    @Binding var operand: UInt16
    var operandType: Instruction.OperandType

    @State private var showPopover = false

    var body: some View {
        Button(action: {
            showPopover.toggle()
        }) {
            Text("Operand: \(String(format: "%04X", operand))")
                .font(.headline)
                .padding()
        }
        .popover(isPresented: $showPopover) {
            OperandSelectionView(operand: $operand, operandType: operandType)
                .frame(width: 200, height: 150)
        }
    }
}

struct OperandSelectionView: View {
    @Binding var operand: UInt16
    var operandType: Instruction.OperandType

    var body: some View {
        VStack {
            Text("Select \(operandType == .memoryAddress ? "Memory Address" : "Value")")
                .font(.headline)

            // Simple slider for value selection (this can be replaced by more complex inputs)
            Slider(value: Binding(get: {
                Double(operand)
            }, set: { newValue in
                operand = UInt16(newValue)
            }), in: 0...Double(UInt16.max))

            Text(String(format: "Selected: %04X", operand))
                .padding()
        }
        .padding()
    }
}
*/
