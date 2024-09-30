//
//  CodeItemView.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

// New View for the CodeItem List
struct CodeItemListView: View {
    @ObservedObject var codeItem: CodeItem
    @Binding var selectedInstruction: Instruction?
    @Binding var selectedInstructionIndex: Int?
        
    var body: some View {
        List(Array(codeItem.codes.enumerated()), id: \.offset) { index, instruction in
            let offset = String(format: "%04X", index)
            
            HStack {
                Text(offset)
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 50, alignment: .leading)
                    .foregroundStyle( index == codeItem.currInstr ? .primary : .secondary)
                
                Button(action: {
                    selectedInstruction = instruction
                    selectedInstructionIndex = index
                }) {
                    Text(instruction.toString())
                        .frame(minWidth: 60)
                }
                .contextMenu {
                    Section(header: Text("Instructions")) {
                        Button("NOP", action: {
                            codeItem.codes[index] = .nop(nil)
                        })
                    }
                }
                
                switch instruction {
                case .ldi(let meta, let register, let value):
                    HStack {
                        Int8RegisterMenu(
                            selectedRegister: Binding(
                                get: { register },
                                set: { newRegister in
                                    codeItem.codes[index] = .ldi(meta, newRegister, value)
                                }
                            )
                        )
                        
                        ChipCadeDataTextField(
                            chipCadeData: Binding(
                                get: { value },
                                set: { newValue in
                                    codeItem.codes[index] = .ldi(meta, register, newValue)
                                }
                            )
                        )
                    }
                default: Text("");
                }
            }
        }
    }
}
