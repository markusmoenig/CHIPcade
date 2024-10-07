//
//  SpriteImageTextField.swift
//  CHIPcade
//
//  Created by Markus Moenig on 7/10/24.
//

import SwiftUI

struct SpriteImageTextField: View {
    var instruction: Instruction
    var undoManager: UndoManager?
    var codeItem: CodeItem
    var index: Int
    
    @State private var textValue: String = ""

    var body: some View {
        TextField("Sprite Image", text: $textValue)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onAppear {
                // Initialize the text field with the memory value from the instruction
                textValue = instruction.memory ?? ""
            }
            .onSubmit {
                // Clone the instruction before modifying it
                let newInstruction = instruction.clone()
                parseMemory(from: textValue, for: newInstruction)

                // Register the change with undo/redo
                codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Sprite Image Changed")

                // Update the text field with the formatted instruction
                textValue = newInstruction.memory ?? ""
            }
    }

    // Helper function to parse the memory value and update the instruction
    private func parseMemory(from text: String, for instruction: Instruction) {
        // Trim whitespace from the input and assign it to memory
        instruction.memory = text.trimmingCharacters(in: .whitespaces)
    }
}
