//
//  ResolutionTextField.swift
//  CHIPcade
//
//  Created by Markus Moenig on 20/10/24.
//

import SwiftUI

struct ResolutionTextField: View {
    var instruction: Instruction
    var undoManager: UndoManager?
    var codeItem: CodeItem
    var index: Int
    
    @State private var resolutionText: String = ""

    var body: some View {
        TextField("WidthxHeight", text: $resolutionText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onAppear {
                // Initialize with the formatted resolution from the instruction
                resolutionText = instruction.memory!
            }
            .onSubmit {
                // Validate and update the resolution
                if validateResolution(text: resolutionText) {
                    // Clone the instruction before modifying it
                    let newInstruction = instruction.clone()
                    
                    newInstruction.memory = resolutionText
                    
                    // Register the change with undo/redo
                    codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Resolution Changed")
                    resolutionText = instruction.memory ?? "320x200"

                } else {
                    // Revert to the old value if the input is invalid
                    resolutionText = instruction.memory ?? "320x200"
                }
            }
    }

    private func validateResolution(text: String) -> Bool {
        // Check if the text is in the format "WIDTHxHEIGHT" where both WIDTH and HEIGHT are integers
        let components = text.split(separator: "x")
        if components.count == 2,
           let width = Int(components[0]),
           let height = Int(components[1]),
           width > 0, height > 0 {
            return true
        }
        return false
    }
}
