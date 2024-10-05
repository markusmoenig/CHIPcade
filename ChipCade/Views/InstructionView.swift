//
//  Untitled.swift
//  CHIPcade
//
//  Created by Markus Moenig on 5/10/24.
//

import SwiftUI

struct InstructionTextFieldView: View {
    @Binding var instruction: Instruction

    @State private var temporaryInput: String = ""

    var body: some View {
        TextField("Instr", text: $temporaryInput)
            .onAppear {
                temporaryInput = instruction.toString()
            }
            .onSubmit {
                if let instructionType = InstructionType.fromString(temporaryInput) {
                    instruction = Instruction(instructionType)
                } else {
                    temporaryInput = instruction.toString()
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(maxWidth: 60)
            .foregroundStyle(instruction.isGCP() ? .yellow : .primary)
    }
}
