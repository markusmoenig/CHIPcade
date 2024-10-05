//
//  MemoryAddressTextField.swift
//  CHIPcade
//
//  Created by Markus Moenig on 5/10/24.
//

import SwiftUI

struct MemoryAddressTextField: View {
    @ObservedObject var instruction: Instruction

    @State private var combinedText: String = ""

    var body: some View {
        TextField("Memory + Offset (Hex)", text: $combinedText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onAppear {
                // Initialize with formatted text from the instruction
                combinedText = formatLDInstruction()
            }
            .onSubmit {
                // Parse memory and offset when the user submits the text field
                parseMemoryAndOffset(from: combinedText)
                // After parsing, update the view with the formatted instruction
                combinedText = formatLDInstruction()
            }
            //.frame(width: 200)
    }

    // Helper function to format the LD instruction into a string
    private func formatLDInstruction() -> String {
        let memoryText = instruction.memory ?? "Data"
        let offsetText = instruction.memoryOffset != nil ? String(format: "0x%X", instruction.memoryOffset!) : "0x0"
        return "\(memoryText) + \(offsetText)"
    }

    // Helper function to parse the input and separate memory and offset
    private func parseMemoryAndOffset(from text: String) {
        // Split the input string based on " + "
        let components = text.components(separatedBy: " + ")
        
        if components.count == 2 {
            // Extract memory
            instruction.memory = components[0].trimmingCharacters(in: .whitespaces)
            
            // Extract and parse the offset, handling 0x prefix or no prefix
            let offsetString = components[1].trimmingCharacters(in: .whitespaces).lowercased()
            if offsetString.hasPrefix("0x") {
                let hexOffset = String(offsetString.dropFirst(2)) // Remove "0x" prefix
                if let offset = Int(hexOffset, radix: 16) {
                    instruction.memoryOffset = offset
                } else {
                    instruction.memoryOffset = 0 // Default to 0 if parsing fails
                }
            } else {
                if let offset = Int(offsetString, radix: 16) {
                    instruction.memoryOffset = offset
                } else {
                    instruction.memoryOffset = 0 // Default to 0 if parsing fails
                }
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
