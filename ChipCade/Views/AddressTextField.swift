//
//  MemoryAddressTextField.swift
//  CHIPcade
//
//  Created by Markus Moenig on 5/10/24.
//

import SwiftUI

struct MemoryAddressTextField: View {
    var instruction: Instruction
    var undoManager: UndoManager?
    var codeItem: CodeItem
    var index: Int
    
    @State private var combinedText: String = ""

    var body: some View {
        TextField("Memory + Offset (Hex)", text: $combinedText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onAppear {
                // Initialize with formatted text from the instruction
                combinedText = formatLDInstruction()
            }
            .onSubmit {
                // Clone the instruction before modifying it
                let newInstruction = instruction.clone()
                parseMemoryAndOffset(from: combinedText, for: newInstruction)

                // Register the change with undo/redo
                codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Memory Address Changed")

                // Update the text field with the new formatted instruction
                combinedText = formatLDInstruction()
            }
    }

    private func formatLDInstruction() -> String {
        let memoryText = instruction.memory ?? "Data"
        let offsetText = instruction.memoryOffset != nil ? String(format: "%d", instruction.memoryOffset!) : "0"
        return "\(memoryText) + \(offsetText)"
    }

    private func parseMemoryAndOffset(from text: String, for instruction: Instruction) {
        let components = text.components(separatedBy: " + ")
        
        if components.count == 2 {
            // Extract memory
            instruction.memory = components[0].trimmingCharacters(in: .whitespaces)
            
            // Extract and parse the offset, handling 0x prefix or no prefix
            let offsetString = components[1].trimmingCharacters(in: .whitespaces).lowercased()
            if offsetString.hasPrefix("0x") {
                let hexOffset = String(offsetString.dropFirst(2))
                instruction.memoryOffset = Int(hexOffset, radix: 16) ?? 0
            } else {
                instruction.memoryOffset = Int(offsetString) ?? 0
            }
        } else if components.count == 1 {
            // No offset provided, set memory and default offset to 0
            instruction.memory = components[0].trimmingCharacters(in: .whitespaces)
            instruction.memoryOffset = 0
        } else {
            // Invalid input, set defaults
            instruction.memory = "Data"
            instruction.memoryOffset = 0
        }
    }
}
