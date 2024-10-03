//
//  CodeItemView.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct CodeItemListView: View {
    @ObservedObject var codeItem: CodeItem
    @Binding var selectedInstruction: Instruction?
    @Binding var selectedInstructionIndex: Int?
        
    @State private var isPopoverPresented = false
    @State private var instructionName: String = ""
    @State private var instructionComment: String = ""
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            HStack {
                Text("Module")
                    .font(.system(.title2))
                    .padding(.leading, 10)
                    .foregroundColor(.secondary)
                Text("\(codeItem.name)")
                    .font(.system(.title2))
                    .padding(.trailing, 10)

                Spacer()
                
                editMenu
                    .popover(isPresented: $isPopoverPresented) {
                        VStack {
                            Text("Set Marker / Comment")
                                .font(.headline)
                                .padding()

                            TextField("Marker", text: $instructionName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(6)
                            
                            TextField("Comment", text: $instructionComment)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(6)

                            Button("Apply") {
                                if let index = selectedInstructionIndex {
                                    codeItem.codes[index].meta.marker = instructionName
                                    codeItem.codes[index].meta.comment = instructionComment
                                    let instr = codeItem.codes[index]
                                    codeItem.codes[index] = instr
                                }
                                isPopoverPresented = false
                            }
                            .padding()
                        }
                        //.frame(width: 300, height: 200)
                    }
            }
            .padding(4)
                        
            List(Array(codeItem.codes.enumerated()), id: \.1.id) { index, instruction in
                let offset = String(format: "%04X", index)
                
                VStack(alignment: .leading) {
                    
                    if !instruction.meta.marker.isEmpty || !instruction.meta.comment.isEmpty {
                        
                        HStack {
                            if !instruction.meta.marker.isEmpty {
                                Text("\(instruction.meta.marker)")
                                    .foregroundColor(.accentColor)
                            }
                            
                            Spacer()
                            
                            if !instruction.meta.comment.isEmpty {
                                Text("\(instruction.meta.comment)")
                                    .foregroundColor(.secondary)
                                    .frame(alignment: .trailing)
                            }
                        }
                    }
                    
                    HStack {
                        Text(offset)
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 50, alignment: .leading)
                            .foregroundStyle( index == selectedInstructionIndex ? .primary : .secondary)
                            .onTapGesture {
                                selectedInstructionIndex = index
                            }
                        
                        Button(action: {
                            selectedInstruction = instruction
                            selectedInstructionIndex = index
                        }) {
                            Text(instruction.toString())
                                .frame(minWidth: 60)
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
    }
    
    var editMenu : some View {
        Menu {
            Section(header: Text("Instruction")) {
                
                Menu("Change To") {
                    Menu("CPU") {
                        Button("LDI", action: {
                            if let selectedInstructionIndex = selectedInstructionIndex {
                                codeItem.writeCode(at: selectedInstructionIndex, value: Instruction(.ldi))
                            }
                        })
                    }
                    
                    Menu("GCP") {
                        Button("RECT", action: {
                            if  let selectedInstructionIndex = selectedInstructionIndex {
                                codeItem.writeCode(at: selectedInstructionIndex, value: Instruction(.rect))
                            }
                        })
                    }
                    
                    Button("NOP", action: {
                        if let selectedInstructionIndex = selectedInstructionIndex {
                            codeItem.writeCode(at: selectedInstructionIndex, value: Instruction(.nop))
                        }
                    })
                    
                }
                
                Menu("Insert NOP") {
                    Button("Before", action: {
                        if let selectedInstructionIndex = selectedInstructionIndex {
                            let nopInstruction = Instruction(.nop)
                            codeItem.insertBefore(at: selectedInstructionIndex, instruction: nopInstruction)
                        }
                    })
                    .keyboardShortcut("I", modifiers: [.shift])
                    
                    Button("After", action: {
                        if let selectedInstructionIndex = selectedInstructionIndex {
                            let nopInstruction = Instruction(.ldi)
                            codeItem.insertAfter(at: selectedInstructionIndex, instruction: nopInstruction.clone())
                        }
                    })
                    .keyboardShortcut("I")
                }
                
                Button("Duplicate", action: {
                    if let selectedInstructionIndex = selectedInstructionIndex {
                        codeItem.duplicate(at: selectedInstructionIndex)
                    }
                })
                .keyboardShortcut("D")
                
                Divider()

                Button("Set Marker / Comment") {
                    if let selectedInstructionIndex = selectedInstructionIndex {
                        let instruction = codeItem.codes[selectedInstructionIndex]
                        instructionName = instruction.meta.marker
                        instructionComment = instruction.meta.comment
                        isPopoverPresented = true
                    }
                }
                
                Divider()
                
                Button("Delete", action: {
                    if let selectedInstructionIndex = selectedInstructionIndex {
                        codeItem.delete(at: selectedInstructionIndex)
                    }
                })
                .keyboardShortcut("X")
            }
        }
        label: {
            Label("Edit Instruction", systemImage: "gear")
        }
        .menuStyle(.borderlessButton)
    }
}
