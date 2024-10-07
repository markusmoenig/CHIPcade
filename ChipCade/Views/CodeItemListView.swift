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
        
    @Environment(\.undoManager) var undoManager

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
                        
//                        Button(action: {
//                            selectedInstruction = instruction
//                            selectedInstructionIndex = index
//                        }) {
//                            Text(instruction.toString())
//                                .frame(minWidth: 60)
//                        }
                        
                        InstructionTextFieldView(instruction: $codeItem.codes[index], codeItem: codeItem, index: index)
                        
                        switch instruction.type {
                        case .inc, .dec:
                            HStack {
                                Int8RegisterMenu(
                                    selectedRegister: Binding(
                                        get: { instruction.register1! },
                                        set: { newRegister in
                                            let newInstruction = instruction.clone()
                                            newInstruction.register1 = newRegister
                                            codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Register Changed")
                                        }
                                    )
                                )                                
                            }
                        case .ld:
                            HStack {
                                Int8RegisterMenu(
                                    selectedRegister: Binding(
                                        get: { instruction.register1! },
                                        set: { newRegister in
                                            let newInstruction = instruction.clone()
                                            newInstruction.register1 = newRegister
                                            codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Register Changed")
                                        }
                                    )
                                )
                                
                                MemoryAddressTextField(
                                    instruction: instruction,
                                    undoManager: undoManager,
                                    codeItem: codeItem,
                                    index: index
                                )
                            }
                        case .ldi:
                            HStack {
                                Int8RegisterMenu(
                                    selectedRegister: Binding(
                                        get: { instruction.register1! },
                                        set: { newRegister in
                                            let newInstruction = instruction.clone()
                                            newInstruction.register1 = newRegister
                                            codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Register Changed")
                                        }
                                    )
                                )
                                
                                ChipCadeDataTextField(
                                    chipCadeData: Binding(
                                        get: { instruction.value! },
                                        set: { newValue in
                                            let newInstruction = instruction.clone()
                                            newInstruction.value = newValue
                                            codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Value Changed")
                                        }
                                    )
                                )
                            }
                        case .st:
                            HStack {
                                MemoryAddressTextField(
                                    instruction: instruction,
                                    undoManager: undoManager,
                                    codeItem: codeItem,
                                    index: index
                                )
                                
                                Int8RegisterMenu(
                                    selectedRegister: Binding(
                                        get: { instruction.register1! },
                                        set: { newRegister in
                                            let newInstruction = instruction.clone()
                                            newInstruction.register1 = newRegister
                                            codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Register Changed")
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
                        Button("LD", action: {
                            if let selectedInstructionIndex = selectedInstructionIndex {
                                codeItem.writeCode(at: selectedInstructionIndex, value: Instruction(.ld), using: undoManager)
                            }
                        })
                        Button("LDI", action: {
                            if let selectedInstructionIndex = selectedInstructionIndex {
                                codeItem.writeCode(at: selectedInstructionIndex, value: Instruction(.ldi), using: undoManager)
                            }
                        })
                        Button("ST", action: {
                            if let selectedInstructionIndex = selectedInstructionIndex {
                                codeItem.writeCode(at: selectedInstructionIndex, value: Instruction(.st), using: undoManager)
                            }
                        })
                        Button("INC", action: {
                            if let selectedInstructionIndex = selectedInstructionIndex {
                                codeItem.writeCode(at: selectedInstructionIndex, value: Instruction(.inc), using: undoManager)
                            }
                        })
                        Button("DEC", action: {
                            if let selectedInstructionIndex = selectedInstructionIndex {
                                codeItem.writeCode(at: selectedInstructionIndex, value: Instruction(.dec), using: undoManager)
                            }
                        })
                    }
                    
                    Menu("GCP") {
                        Button("RECT", action: {
                            if  let selectedInstructionIndex = selectedInstructionIndex {
                                codeItem.writeCode(at: selectedInstructionIndex, value: Instruction(.rect), using: undoManager)
                            }
                        })
                    }
                    
                    Button("NOP", action: {
                        if let selectedInstructionIndex = selectedInstructionIndex {
                            codeItem.writeCode(at: selectedInstructionIndex, value: Instruction(.nop), using: undoManager)
                        }
                    })
                    
                }
                
                Menu("Insert NOP") {
                    Button("Before", action: {
                        if let selectedInstructionIndex = selectedInstructionIndex {
                            let nopInstruction = Instruction(.nop)
                            codeItem.insertBefore(at: selectedInstructionIndex, instruction: nopInstruction, using: undoManager)
                        }
                    })
                    .keyboardShortcut("I", modifiers: [.shift])
                    
                    Button("After", action: {
                        if let selectedInstructionIndex = selectedInstructionIndex {
                            let nopInstruction = Instruction(.nop)
                            codeItem.insertAfter(at: selectedInstructionIndex, instruction: nopInstruction.clone(), using: undoManager)
                        }
                    })
                    .keyboardShortcut("I")
                }
                
                Button("Duplicate", action: {
                    if let selectedInstructionIndex = selectedInstructionIndex {
                        codeItem.duplicate(at: selectedInstructionIndex, using: undoManager)
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
                        codeItem.delete(at: selectedInstructionIndex, using: undoManager)
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
