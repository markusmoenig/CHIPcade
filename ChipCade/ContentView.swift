//
//  ContentView.swift
//  ChipCade
//
//  Created by Markus Moenig on 28/9/24.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: ChipCadeDocument
    
    @State private var selectedCodeItem: CodeItem? = nil
    @State private var selectedMemoryItem: MemoryItem? = nil
    
    @State private var selectedInstructionIndex: Int?
    @State private var selectedInstruction: Instruction?

    @State private var showingAddMemoryItemPopover = false

    @State private var previewIsLeftSide = false

    var body: some View {
        NavigationView {
            List {
                // Code Section
                CodeSectionView(title: "Code", codeItems: $document.game.codeItems, selectedCodeItem: $selectedCodeItem, selectedMemoryItem: $selectedMemoryItem)
                
                // Sprite Section
                MemorySectionView(title: "Sprites", memoryItems: $document.game.spriteItems, selectedMemoryItem: $selectedMemoryItem, selectedCodeItem: $selectedCodeItem)
                
                // Data Section
                MemorySectionView(title: "Data", memoryItems: $document.game.dataItems, selectedMemoryItem: $selectedMemoryItem, selectedCodeItem: $selectedCodeItem)
                
                #if !os(iOS)
                Divider()
                #endif
                
                Button(action: {
                    selectedCodeItem = nil
                    selectedMemoryItem = nil
                }) {
                    HStack {
                        Text("Palette")
                            .foregroundColor(.primary)
                            .padding(.leading, 10)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill((selectedCodeItem == nil && selectedMemoryItem == nil) ? Color.accentColor.opacity(0.2) : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200, maxWidth: 250)
  
            HStack(spacing: 0) {
                
                VStack(spacing: 0) {
                    
                    Spacer()
                    
                    if let codeItem = selectedCodeItem, previewIsLeftSide == true {
                        CodeItemListView(
                            codeItem: codeItem,
                            selectedInstruction: $selectedInstruction,
                            selectedInstructionIndex: $selectedInstructionIndex
                        )
                    } else {
                        MetalView(document.game, .Preview)
                    }
                    
                    Spacer()
                    Divider()

                    MetalView(document.game, .CPU)
                        .frame(maxHeight: 200)
                }
                
                Divider()
                
                VStack(spacing: 0) {
                    if let codeItem = selectedCodeItem {
                        if !previewIsLeftSide {
                            CodeItemListView(
                                codeItem: codeItem,
                                selectedInstruction: $selectedInstruction,
                                selectedInstructionIndex: $selectedInstructionIndex
                            )
                        } else {
                            MetalView(document.game, .Preview)
                        }
                    } else
                    if let memoryItem = selectedMemoryItem {
                        MemoryGridView(memoryItem: memoryItem)
                    } else {
                        PaletteView(game: document.game)
                            .padding(0)
                    }

                    
                    Spacer()
                    Divider()
                        
                    StackView(game: document.game)
                        .frame(height: 150)
                }
                .frame(maxWidth: 350)
            }
        }
        
        .navigationTitle("Memory Items")
        .toolbar {
            
            ToolbarItemGroup(placement: .primaryAction) {
                
                Button(action: {
                    document.game.execute()
                }) {
                    Label("Play", systemImage: "play")
                }
                
                Button(action: {
                    document.game.execute_instruction()
                    document.game.currInstructionIndex += 1
                    selectedInstructionIndex = document.game.currInstructionIndex
                    document.game.cpuRender.update()
                }) {
                    Label("Step", systemImage: "playpause")
                }
                
                Spacer()
                
                Button(action: {
                    previewIsLeftSide.toggle()
                }) {
                    Label("Swap", systemImage: "rectangle.2.swap")
                }
                .keyboardShortcut("R")

                editMenu
                
                Spacer()

                // Toolbar button for adding a new MemoryItem
                Button(action: {
                    showingAddMemoryItemPopover.toggle() // Toggle popover visibility
                }) {
                    Label("Add Memory Item", systemImage: "plus")
                }
                .popover(isPresented: $showingAddMemoryItemPopover) {
                    AddMemoryItemView(game: document.game, selectedMemoryItem: $selectedMemoryItem)
                }
            }
        }
        .onAppear {
            selectedCodeItem = document.game.codeItems[0]
        }
        .onChange(of: selectedInstructionIndex) {
            if let selectedInstructionIndex = selectedInstructionIndex {
                document.game.currInstructionIndex = selectedInstructionIndex
            }
            document.game.cpuRender.update()
        }
        .onChange(of: selectedCodeItem) {
            document.game.currInstructionIndex = 0
            selectedInstructionIndex = 0
            document.game.selectionState = .code
        }
    }
    
    var editMenu : some View {
        Menu {
            Section(header: Text("Instructions")) {
                
                
                Menu("Change To") {
                    Menu("Register") {
                        Button("LDI", action: {
                            if let selectedCodeItem = selectedCodeItem, let selectedInstructionIndex = selectedInstructionIndex {
                                selectedCodeItem.writeCode(at: selectedInstructionIndex, value: Instruction(.ldi))
                            }
                        })
                    }
                    
                    Menu("GCP") {
                        Button("RECT", action: {
                            if let selectedCodeItem = selectedCodeItem, let selectedInstructionIndex = selectedInstructionIndex {
                                selectedCodeItem.writeCode(at: selectedInstructionIndex, value: Instruction(.rect))
                            }
                        })
                    }
                    
                    Button("NOP", action: {
                        if let selectedCodeItem = selectedCodeItem, let selectedInstructionIndex = selectedInstructionIndex {
                            selectedCodeItem.writeCode(at: selectedInstructionIndex, value: Instruction(.nop))
                        }
                    })
                    
                }
                
                Menu("Insert NOP") {
                    Button("Before", action: {
                        if let selectedCodeItem = selectedCodeItem {
                            if let selectedInstructionIndex = selectedInstructionIndex {
                                let nopInstruction = Instruction(.nop)
                                selectedCodeItem.insertBefore(at: selectedInstructionIndex, instruction: nopInstruction)
                            }
                        }
                    })
                    .keyboardShortcut("I", modifiers: [.shift])
                    
                    Button("After", action: {
                        if let selectedCodeItem = selectedCodeItem {
                            if let selectedInstructionIndex = selectedInstructionIndex {
                                let nopInstruction = Instruction(.nop)
                                selectedCodeItem.insertAfter(at: selectedInstructionIndex, instruction: nopInstruction)
                            }
                        }
                    })
                    .keyboardShortcut("I")
                }
                
                Button("Duplicate", action: {
                    if let selectedCodeItem = selectedCodeItem {
                        if let selectedInstructionIndex = selectedInstructionIndex {
                            selectedCodeItem.duplicate(at: selectedInstructionIndex)
                        }
                    }
                })
                .keyboardShortcut("D")
                
                Divider()
                
                Button("Delete", action: {
                    if let selectedCodeItem = selectedCodeItem {
                        if let selectedInstructionIndex = selectedInstructionIndex {
                            selectedCodeItem.delete(at: selectedInstructionIndex)
                        }
                    }
                })
                .keyboardShortcut("X")
            }
        }
        label: {
            Label("Edit", systemImage: "pencil")
            //Text("\(document.core.project!.size.x) x \(document.core.project!.size.y)")
        }
    }
}

struct AddMemoryItemView: View {
    @ObservedObject var game: Game
    @Binding var selectedMemoryItem: MemoryItem?
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = "New Memory Item"
    @State private var selectedType: MemoryType = .code
    @State private var length: Int = 64

    var body: some View {
        VStack(alignment: .leading) {
            Text("Add Memory Item")
                .font(.headline)
                .padding(.top)
                //.foregroundColor(Color.secondary)

            VStack(alignment: .leading, spacing: 10) {
                TextField("Enter name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
                
                Picker("Type", selection: $selectedType) {
                    Text("Code").tag(MemoryType.code)
                    Text("Sprite").tag(MemoryType.sprite)
                    Text("Data").tag(MemoryType.data)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 10)
                
//                Text("Length: \(length) bytes")
//                Stepper(value: $length, in: 1...1024) {
//                    Text("Length: \(length) bytes")
//                }
            }
            .padding()
            
            HStack {
                //Spacer()
                Button("Add") {
                    addMemoryItem()
                    presentationMode.wrappedValue.dismiss()
                }
                //.buttonStyle(DefaultButtonStyle())
            }
            .padding(.bottom)
        }
        .padding()
    }
    
    private func addMemoryItem() {
        let newItem = MemoryItem(name: name, length: length, type: selectedType)
        let newCodeItem = CodeItem(name: name)

        // Add the new memory item to the appropriate section
        switch selectedType {
        case .code:
            game.codeItems.append(newCodeItem)
        case .sprite:
            game.spriteItems.append(newItem)
        case .data:
            game.dataItems.append(newItem)
        }

        // Automatically select the new memory item
        selectedMemoryItem = newItem
    }
}

#Preview {
    ContentView(document: .constant(ChipCadeDocument()))
}
