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
    @State private var instructionTag: String = ""
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
            }
            .padding(.trailing, 20)

            HStack(spacing: 8) {
                Button(action: {
                    if let selectedInstructionIndex = selectedInstructionIndex {
                        let nopInstruction = Instruction(.nop)
                        codeItem.insertBefore(at: selectedInstructionIndex, instruction: nopInstruction, using: undoManager)
                    }
                }) {
                    Label("", systemImage: "arrow.up.to.line.compact")
//                    Label("", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderless)
                .controlSize(.large)
                .keyboardShortcut("B")//, modifiers: [.shift])
                
                Button(action: {
                    if let selectedInstructionIndex = selectedInstructionIndex {
                        let nopInstruction = Instruction(.nop)
                        codeItem.insertAfter(at: selectedInstructionIndex, instruction: nopInstruction.clone(), using: undoManager)
                    }
                }) {
                    Label("", systemImage: "arrow.down.to.line.compact")
                    //Label("", systemImage: "plus.circle")
                }
                .buttonStyle(.borderless)
                .controlSize(.large)
                .keyboardShortcut("I")
                
                Button(action: {
                    if let selectedInstructionIndex = selectedInstructionIndex {
                        codeItem.duplicate(at: selectedInstructionIndex, using: undoManager)
                    }
                }) {
                    Label("", systemImage: "doc.on.doc.fill")
                }
                .buttonStyle(.borderless)
                .controlSize(.large)
                .keyboardShortcut("D")
                
                Button(action: {
                    if let selectedInstructionIndex = selectedInstructionIndex {
                        codeItem.delete(at: selectedInstructionIndex, using: undoManager)
                    }
                }) {
                    Label("", systemImage: "trash.fill")
                }
                .buttonStyle(.borderless)
                .controlSize(.large)
                .keyboardShortcut(.delete)
                
                Spacer()
            }
            .padding(.top, 4)
            .padding(.bottom, 4)
            .padding(.leading, 8)

            List(Array(codeItem.codes.enumerated()), id: \.1.id) { index, instruction in
                let offset = String(format: "%04d", index)
                
                VStack(alignment: .leading) {
                    HStack {
                        
                        if instruction.type != .comnt {
                            Text(offset)
                                .font(.system(.body, design: .monospaced))
                                .frame(alignment: .leading)
                                .foregroundStyle(itemStyle(index))
                                .onTapGesture {
                                    selectedInstructionIndex = index
                                }
                            
                            InstructionTextFieldView(instruction: $codeItem.codes[index], codeItem: codeItem, index: index)
                        } else {
                            Text("##")
                                .font(.system(.body, design: .monospaced))
//                                .frame(width: 50, alignment: .leading)
                                //.foregroundStyle(.secondary)
                                .foregroundStyle(itemStyle(index))
                                .onTapGesture {
                                    selectedInstructionIndex = index
                                }
                        }
                        
                        switch instruction.type {
                        case .cmp, .add, .sub, .div, .mod, .mul:
                            HStack {
                                Int8FullRegisterMenu(
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
                        case .comnt:
                            CommentTextField(
                                instruction: instruction,
                                undoManager: undoManager,
                                codeItem: codeItem,
                                index: index
                            )
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
                        case .call, .j, .je, .jne, .jl, .jg, .jc, .jo:
                            CodeAddressTextField(
                                instruction: instruction,
                                undoManager: undoManager,
                                codeItem: codeItem,
                                index: index
                            )
                        case .calltm:
                            CodeAddressTextField(
                                instruction: instruction,
                                undoManager: undoManager,
                                codeItem: codeItem,
                                index: index
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
                        case .ldi, .rand:
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
                        case .sprgrp, .sprcol, .sprfps, .sprfri, .sprrot, .sprx, .spry, .sprspd, .spracc, .sprimg, .sprmxs, .sprpri, .sprvis, .sprwrp:
                            HStack {
                                SpriteIndexTextField(
                                    spriteIndex: Binding(
                                        get: { Int(instruction.register1!) },
                                        set: { newRegister in
                                            let newInstruction = instruction.clone()
                                            newInstruction.register1 = UInt8(newRegister)
                                            codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Sprite Changed")
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
                        case .ldresx, .ldresy:
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
                        case .lyrres:
                            HStack {
                                Int8LayerMenu(
                                    selectedLayer: Binding(
                                        get: { instruction.register1! },
                                        set: { newLayer in
                                            let newInstruction = instruction.clone()
                                            newInstruction.register1 = newLayer
                                            codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Layer Changed")
                                        }
                                    )
                                )
                                ResolutionTextField(
                                    instruction: instruction,
                                    undoManager: undoManager,
                                    codeItem: codeItem,
                                    index: index
                                )
                            }
                        case .lyrvis:
                            HStack {
                                Int8LayerMenu(
                                    selectedLayer: Binding(
                                        get: { instruction.register1! },
                                        set: { newLayer in
                                            let newInstruction = instruction.clone()
                                            newInstruction.register1 = newLayer
                                            codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Layer Changed")
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
                        case .sprlyr:
                            HStack {
                                SpriteIndexTextField(
                                    spriteIndex: Binding(
                                        get: { Int(instruction.register1!) },
                                        set: { newRegister in
                                            let newInstruction = instruction.clone()
                                            newInstruction.register1 = UInt8(newRegister)
                                            codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Sprite Changed")
                                        }
                                    )
                                )
                                Int8LayerMenu(
                                    selectedLayer: Binding(
                                        get: { instruction.register2! },
                                        set: { newLayer in
                                            let newInstruction = instruction.clone()
                                            newInstruction.register2 = newLayer
                                            codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Layer Changed")
                                        }
                                    )
                                )
                            }
                        case .sprset:
                            HStack {
                                SpriteIndexTextField(
                                    spriteIndex: Binding(
                                        get: { Int(instruction.register1!) },
                                        set: { newRegister in
                                            let newInstruction = instruction.clone()
                                            newInstruction.register1 = UInt8(newRegister)
                                            codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Sprite Changed")
                                        }
                                    )
                                )
                                
                                SpriteImageTextField(
                                    instruction: instruction,
                                    undoManager: undoManager,
                                    codeItem: codeItem,
                                    index: index
                                )
                            }
                        case .spranm:
                            SpriteIndexTextField(
                                spriteIndex: Binding(
                                    get: { Int(instruction.register1!) },
                                    set: { newRegister in
                                        let newInstruction = instruction.clone()
                                        newInstruction.register1 = UInt8(newRegister)
                                        codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Sprite Changed")
                                    }
                                )
                            )
                            SpriteIndexTextField(
                                spriteIndex: Binding(
                                    get: { Int(instruction.register2!) },
                                    set: { newRegister in
                                        let newInstruction = instruction.clone()
                                        newInstruction.register2 = UInt8(newRegister)
                                        codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Range Changed")
                                    }
                                )
                            )
                            SpriteIndexTextField(
                                spriteIndex: Binding(
                                    get: { Int(instruction.register3!) },
                                    set: { newRegister in
                                        let newInstruction = instruction.clone()
                                        newInstruction.register3 = UInt8(newRegister)
                                        codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Range Changed")
                                    }
                                )
                            )
                        case .sprstp:
                            SpriteIndexTextField(
                                spriteIndex: Binding(
                                    get: { Int(instruction.register1!) },
                                    set: { newRegister in
                                        let newInstruction = instruction.clone()
                                        newInstruction.register1 = UInt8(newRegister)
                                        codeItem.aboutToChange(using: undoManager, newInstruction: newInstruction, at: index, text: "Sprite Changed")
                                    }
                                )
                            )
                        case .st:
                            HStack {
                                MemoryAddressTextField(
                                    instruction: instruction,
                                    undoManager: undoManager,
                                    codeItem: codeItem,
                                    index: index
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
                        case .tag:
                            TagTextField(
                                instruction: instruction,
                                undoManager: undoManager,
                                codeItem: codeItem,
                                index: index
                            )
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
                    
                
                /*
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

                Button("Set Tag / Comment") {
                    if let selectedInstructionIndex = selectedInstructionIndex {
                        let instruction = codeItem.codes[selectedInstructionIndex]
                        instructionTag = instruction.meta.tag
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
                 */
            }
        }
        label: {
            Label("Change Instruction to", systemImage: "gear")
        }
        .menuStyle(.borderlessButton)
    }
    
    // Returns the item color
    func itemStyle(_ index: Int) -> Color {
        let game = Game.shared
        
        if game.error != .none {
            let codeItemIndex = game.getCodeItemIndex(byItem: codeItem)
            if index == game.errorInstructionIndex && codeItemIndex == game.errorCodeItemIndex {
                return .red
            }
        }
        
        if index == selectedInstructionIndex {
            return .primary;
        } else {
            return .secondary;
        }
    }
}
