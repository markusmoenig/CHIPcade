//
//  StackView.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct InstructionInfoView: View {
    @Binding var selectedInstruction: Instruction?
    @Binding var error: ChipCadeError

    @Binding var errorInstructionType: InstructionType?

    var body: some View {
        VStack {
            if error != .none {
                Spacer()
                Text("\(error.toString) at line \(Game.shared.errorInstructionIndex)")
                    .font(.system(.title))
                    .padding(4)
                    .foregroundStyle(.red)
                Text("Module: \(Game.shared.errorCodeItemIndex == MathLibraryIndex ? "Math" : Game.shared.data.codeItems[Game.shared.errorCodeItemIndex].name)")
                    .font(.system(.headline))
                    .padding(2)
                    .foregroundStyle(.red)
                if let type = Game.shared.errorInstructionType {
                    Text("\(Instruction(type).syntax())")
                        .font(.system(.headline))
                        .foregroundStyle(.secondary)
                        .padding(2)
                }
                Spacer()
            } else
            if let instruction = selectedInstruction {
                Spacer()
                Text("\(instruction.syntax())")
                    .font(.system(.title2))
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
