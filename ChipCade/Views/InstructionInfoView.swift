//
//  StackView.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct InstructionInfoView: View {
    @Binding var selectedInstruction: Instruction?

    var body: some View {
        VStack {
            if let instruction = selectedInstruction {
                Spacer()
                Text("\(instruction.format())")
                    .font(.system(.title))
                    .padding(4)
                Text("\(instruction.description())")
                    .font(.system(.headline))
                    .padding(8)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true) // Allows wrapping
            } else {
                Text("No Instruction")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
