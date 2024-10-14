//
//  CodeAddressTextField.swift
//  CHIPcade
//
//  Created by Markus Moenig on 14/10/24.
//

import SwiftUI

struct CodeAddressTextField: View {
    var instruction: Instruction
    var undoManager: UndoManager?
    var codeItem: CodeItem
    var index: Int
    
    @State private var combinedText: String = ""

    var body: some View {
        TextField("Module.Tag or Tag", text: $combinedText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onAppear {
                // Initialize with formatted text from the instruction
                combinedText = formatCodeAddress()
            }
            .onSubmit {
                let previousText = combinedText
                // Clone the instruction before modifying it
                let newInstruction = instruction.clone()
                
                // Validate and parse the input
                if parseCodeAddress(from: combinedText, for: newInstruction) {
                    // If the input is valid, update the instruction
                    codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Code Address Changed")
                } else {
                    // Revert if the input is invalid
                    combinedText = previousText
                    instruction.memory = previousText
                }
            }
    }

    private func formatCodeAddress() -> String {
        if let memory = instruction.memory, memory.contains(".") {
            return memory
        } else {
            return instruction.memory ?? "Tag"
        }
    }

    private func parseCodeAddress(from text: String, for instruction: Instruction) -> Bool {
        let components = text.components(separatedBy: ".")

        if components.count == 2 {
            // "Module.Tag" form: Save it directly to the memory field
            let module = components[0].trimmingCharacters(in: .whitespaces)
            let tag = components[1].trimmingCharacters(in: .whitespaces)
            instruction.memory = "\(module).\(tag)"
            return !module.isEmpty && !tag.isEmpty
        } else if components.count == 1 {
            // "Tag" form (same module): Save it as the memory field
            let tag = components[0].trimmingCharacters(in: .whitespaces)
            instruction.memory = tag
            return !tag.isEmpty
        } else {
            // Invalid form
            return false
        }
    }
}
