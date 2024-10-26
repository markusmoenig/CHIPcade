//
//  MemoryAddressTextField.swift
//  CHIPcade
//
//  Created by Markus Moenig on 5/10/24.
//

import SwiftUI

struct TagTextField: View {
    var instruction: Instruction
    var undoManager: UndoManager?
    var codeItem: CodeItem
    var index: Int
    
    @State private var combinedText: String = ""

    var body: some View {
        TextField("Tag", text: $combinedText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onAppear {
                // Initialize with formatted text from the instruction
                combinedText = instruction.memory!
            }
            .onSubmit {
                // Clone the instruction before modifying it
                let newInstruction = instruction.clone()
                newInstruction.memory = combinedText
                
                // Register the change with undo/redo
                codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Tag Changed")
            }
            .foregroundStyle(.blue)
    }
}

struct CommentTextField: View {
    var instruction: Instruction
    var undoManager: UndoManager?
    var codeItem: CodeItem
    var index: Int
    
    @State private var combinedText: String = ""

    var body: some View {
        TextField("Comment", text: $combinedText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onAppear {
                // Initialize with formatted text from the instruction
                combinedText = instruction.memory!
            }
            .onSubmit {
                // Clone the instruction before modifying it
                let newInstruction = instruction.clone()
                newInstruction.memory = combinedText
                
                // Register the change with undo/redo
                codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Comment Changed")
            }
            .foregroundStyle(.secondary)
    }
}
