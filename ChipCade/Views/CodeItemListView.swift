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
        List(Array(codeItem.codes.enumerated()), id: \.1.id) { index, instruction in
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
                            codeItem.codes[index] = Instruction(.nop)
                        })
                    }
                }
                
                switch instruction.type {
                case .ldi:
                    HStack {
                        Int8RegisterMenu(
                            selectedRegister: Binding(
                                get: { instruction.register1! },
                                set: { newRegister in
                                    instruction.register1 = newRegister
                                    codeItem.codes[index] = instruction
                                }
                            )
                        )
                        
                        ChipCadeDataTextField(
                            chipCadeData: Binding(
                                get: { instruction.value! },
                                set: { newValue in
                                    instruction.value = newValue
                                    codeItem.codes[index] = instruction
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
