//
//  Untitled.swift
//  CHIPcade
//
//  Created by Markus Moenig on 5/10/24.
//

import SwiftUI

struct InstructionTextFieldView: View {
    @Binding var instruction: Instruction
    @ObservedObject var codeItem: CodeItem
    var index: Int

    @State private var temporaryInput: String = ""

    @Environment(\.undoManager) var undoManager

    var body: some View {
        TextField("Instr", text: $temporaryInput)
            .onAppear {
                temporaryInput = instruction.toString()
            }
            .onSubmit {
                if let instructionType = InstructionType.fromString(temporaryInput) {
                    codeItem.aboutToChange(using: undoManager, newInstruction: Instruction(instructionType), at: index)
                } else {
                    temporaryInput = instruction.toString()
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(maxWidth: 80)
            .foregroundStyle(instruction.color())
    }
}
