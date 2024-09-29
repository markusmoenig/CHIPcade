//
//  ContentView.swift
//  ChipCade
//
//  Created by Markus Moenig on 28/9/24.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: ChipCadeDocument
    
    // The selected code and memory item
    @State private var selectedCodeItem: CodeItem? = nil
    @State private var selectedMemoryItem: MemoryItem? = nil
    
    @State private var selectedInstructionIndex: Int?
    @State private var selectedInstruction: Instruction?

    @State private var showingAddMemoryItemPopover = false

    var body: some View {
        NavigationView {
            List {
                // Code Section
                CodeSectionView(title: "Code", codeItems: $document.game.codeItems, selectedCodeItem: $selectedCodeItem)
                
                // Sprite Section
                MemorySectionView(title: "Sprites", memoryItems: $document.game.spriteItems, selectedMemoryItem: $selectedMemoryItem)
                
                // Data Section
                MemorySectionView(title: "Data", memoryItems: $document.game.dataItems, selectedMemoryItem: $selectedMemoryItem)
                
                // Text Section
                MemorySectionView(title: "Text", memoryItems: $document.game.textItems, selectedMemoryItem: $selectedMemoryItem)
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200, maxWidth: 250)
            
            // Show the opcode editor when an instruction is selected
//            if let selectedInstructionIndex = instructions.firstIndex(where: { $0.id == selectedInstructionID }),
//               let selectedMemoryItemIndex = document.game.codeItems.firstIndex(where: { $0.id == selectedMemoryItem?.id }) {
//                
//                let instructionStartIndex = selectedMemoryItemIndex * 4  // Adjust as needed for your memory layout
//                
//                Divider()
//                OpcodeEditorView(selectedInstruction: $instructions[selectedInstructionIndex],
//                                 memoryItem: $document.game.codeItems[selectedMemoryItemIndex],
//                                 instructionIndex: instructionStartIndex)
//                    .padding()
//            } else {
//                Spacer()
//                    .frame(minWidth: 1280 / 2)
//            }

            Spacer()
                .frame(minWidth: 1280 / 2)
            
            VStack {
                if let codeItem = selectedCodeItem {
                    List(Array(codeItem.codes.enumerated()), id: \.offset) { index, instruction in
                        let offset = String(format: "%04X", index)
                        
                        HStack {
                            // Display the memory offset in hex format
                            Text(String(offset))
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 60, alignment: .leading) // Fixed width for alignment
                            
                            Button(action: {
                                selectedInstruction = instruction
                                selectedInstructionIndex = index
                            }) {
                                Text(instruction.format())
                                    .frame(minWidth: 100)
                            }
                            
                            /*
                            
                            // Show the instruction and make it selectable
                            Text(instruction.format())
                                .padding(.leading, 5)
                                .onTapGesture {
                                    selectedInstruction = instruction
                                    selectedInstructionIndex = index
                                }
                                .background(selectedInstructionIndex == index ? Color.blue.opacity(0.3) : Color.clear) // Highlight selected item
                                .cornerRadius(5)
                             */
                        }
                    }
                    .listStyle(PlainListStyle())  // Keep the list style simple and clean
//                    .onChange(of: selectedInstruction) {
//                        if let updatedInstruction = selectedInstruction {
//                            if let index = instructions.firstIndex(where: { $0.id == updatedInstruction.id }) {
//                                instructions[index] = updatedInstruction  // Update the instruction in the array
//                            }
//                        }
//                    }
                } else
                if let memoryItem = selectedMemoryItem {
                    MemoryGridView(memoryItem: memoryItem)
                } else {
                    Text("No memory item selected")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                }
                
                Spacer()
                Divider()

                StackView(game: document.game)
                    .frame(height: 150)
            }
            
            
        }
        .navigationTitle("Memory Items")
        .toolbar {
            // Toolbar button for adding a new MemoryItem
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    document.game.execute()
                }) {
                    Label("Play", systemImage: "play")
                }
            }
            // Toolbar button for adding a new MemoryItem
            ToolbarItem(placement: .primaryAction) {
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
        // React to changes in selectedMemoryItem to decode instructions
//        .onChange(of: selectedMemoryItem) {
//            if let memoryItem = selectedMemoryItem, memoryItem.type == .code {
//                // Decode instructions every time a new memory item is selected
//                instructions = Instruction.decodeInstructions(from: memoryItem.memory)
//                selectedInstructionID = nil
//                selectedInstruction = nil
//            }
//        }
    }
}

struct CodeSectionView: View {
    let title: String
    @Binding var codeItems: [CodeItem]
    @Binding var selectedCodeItem: CodeItem?

    @State private var isRenaming: Bool = false
    @State private var newName: String = ""

    var body: some View {
        Section(header: Text(title).font(.headline)) {
            ForEach(codeItems.indices, id: \.self) { index in
                HStack {
                    if isRenaming && selectedCodeItem === codeItems[index] {
                        TextField("New Name", text: $newName, onCommit: {
                            codeItems[index].name = newName
                            isRenaming = false
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                    } else {
                        Text(codeItems[index].name)
                            .onTapGesture {
                                selectedCodeItem = codeItems[index]
                            }
                            .padding(.vertical, 4)
                            .background(selectedCodeItem === codeItems[index] ? Color.blue.opacity(0.2) : Color.clear)
                    }

                    Spacer()

                    // Rename and delete buttons for both platforms
                    Button(action: {
                        startRenaming(item: codeItems[index])
                    }) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.trailing, 8)

                    Button(action: {
                        deleteItem(at: index)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .contextMenu {
                    // macOS context menu for renaming and deleting
                    #if os(macOS)
                    Button(action: {
                        startRenaming(item: codeItems[index])
                    }) {
                        Text("Rename")
                        Image(systemName: "pencil")
                    }

                    Button(action: {
                        deleteItem(at: index)
                    }) {
                        Text("Delete")
                        Image(systemName: "trash")
                    }
                    .foregroundColor(.red)
                    #endif
                }
                #if os(iOS)
                .swipeActions {
                    // iOS swipe actions for deleting and renaming
                    Button(role: .destructive) {
                        deleteItem(at: index)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        startRenaming(item: memoryItems[index])
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                #endif
            }
        }
    }

    private func startRenaming(item: CodeItem) {
        newName = item.name
        selectedCodeItem = item
        isRenaming = true
    }

    private func deleteItem(at index: Int) {
        codeItems.remove(at: index)
        selectedCodeItem = nil
    }
}

struct MemorySectionView: View {
    let title: String
    @Binding var memoryItems: [MemoryItem]
    @Binding var selectedMemoryItem: MemoryItem?

    @State private var isRenaming: Bool = false
    @State private var newName: String = ""

    var body: some View {
        Section(header: Text(title).font(.headline)) {
            ForEach(memoryItems.indices, id: \.self) { index in
                HStack {
                    if isRenaming && selectedMemoryItem === memoryItems[index] {
                        TextField("New Name", text: $newName, onCommit: {
                            memoryItems[index].name = newName
                            isRenaming = false
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                    } else {
                        Text(memoryItems[index].name)
                            .onTapGesture {
                                selectedMemoryItem = memoryItems[index]
                            }
                            .padding(.vertical, 4)
                            .background(selectedMemoryItem === memoryItems[index] ? Color.blue.opacity(0.2) : Color.clear)
                    }

                    Spacer()

                    // Rename and delete buttons for both platforms
                    Button(action: {
                        startRenaming(item: memoryItems[index])
                    }) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.trailing, 8)

                    Button(action: {
                        deleteItem(at: index)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .contextMenu {
                    // macOS context menu for renaming and deleting
                    #if os(macOS)
                    Button(action: {
                        startRenaming(item: memoryItems[index])
                    }) {
                        Text("Rename")
                        Image(systemName: "pencil")
                    }

                    Button(action: {
                        deleteItem(at: index)
                    }) {
                        Text("Delete")
                        Image(systemName: "trash")
                    }
                    .foregroundColor(.red)
                    #endif
                }
                #if os(iOS)
                .swipeActions {
                    // iOS swipe actions for deleting and renaming
                    Button(role: .destructive) {
                        deleteItem(at: index)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        startRenaming(item: memoryItems[index])
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                #endif
            }
        }
    }

    private func startRenaming(item: MemoryItem) {
        newName = item.name
        selectedMemoryItem = item
        isRenaming = true
    }

    private func deleteItem(at index: Int) {
        memoryItems.remove(at: index)
        selectedMemoryItem = nil
    }
}

// StackView to display the stack with offsets
struct StackView: View {
    @ObservedObject var game : Game
    
    var body: some View {
        VStack {
            Text("Stack")
                .font(.headline)
                .foregroundColor(.gray)

            List(Array(game.stack.enumerated()), id: \.offset) { index, data in
                HStack {

                    Text(String(format: "%04X", index))
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 60, alignment: .leading)
                    
                    // Display the name or value of the MemoryItem
                    Text(game.stack[index].description())
                        .font(.system(.body, design: .monospaced))
                        .padding(.leading, 5)
                }
            }
            .frame(maxHeight: 150, alignment: .bottom)
        }
    }
}

struct MemoryItemView: View {
    @Binding var memoryItem: MemoryItem
    @State private var isEditingName = false
    
    var body: some View {
        HStack {
            if isEditingName {
                TextField("Name", text: $memoryItem.name, onCommit: {
                    isEditingName = false
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                Text(memoryItem.name)
                    .onTapGesture {
                        isEditingName = true
                    }
            }
            //Spacer()
//            Text("Start: \(memoryItem.startAddress)")
            Text("Length: \(memoryItem.memory.count)")
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
                    Text("Text").tag(MemoryType.text)
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
        case .text:
            game.textItems.append(newItem)
        }

        // Automatically select the new memory item
        selectedMemoryItem = newItem
    }
}

#Preview {
    ContentView(document: .constant(ChipCadeDocument()))
}
