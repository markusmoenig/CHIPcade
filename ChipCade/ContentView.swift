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

    var body: some View {
        NavigationView {
            List {
                // Code Section
                CodeSectionView(title: "Code", codeItems: $document.game.codeItems, selectedCodeItem: $selectedCodeItem, selectedMemoryItem: $selectedMemoryItem)
                
                // Sprite Section
                MemorySectionView(title: "Sprites", memoryItems: $document.game.spriteItems, selectedMemoryItem: $selectedMemoryItem, selectedCodeItem: $selectedCodeItem)
                
                // Data Section
                MemorySectionView(title: "Data", memoryItems: $document.game.dataItems, selectedMemoryItem: $selectedMemoryItem, selectedCodeItem: $selectedCodeItem)
                
                Button(action: {
                    selectedCodeItem = nil
                    selectedMemoryItem = nil
                }) {
                    Text("Palette")
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200, maxWidth: 250)
  
            HStack {
                VStack {
                    
                    Spacer()
                    
                    GeometryReader { geometry in
                        let availableWidth = geometry.size.width
                        let availableHeight = geometry.size.height
                        
                        // Calculate the width and height while maintaining the 16:9 aspect ratio
                        let aspectRatio: CGFloat = 16.0 / 9.0
                        let width = min(availableWidth, availableHeight * aspectRatio)
                        let height = width / aspectRatio
                        
                        MetalView(document.draw2D)
                            .frame(width: width, height: height)
                            .background(Color.black) // Optional background color for contrast
                    }
                    .aspectRatio(16.0 / 9.0, contentMode: .fit) // Enforces 16:9 ratio
                    
                    /*
                     GeometryReader { geometry in
                     let availableWidth = geometry.size.width
                     let availableHeight = geometry.size.height
                     
                     // Calculate dimensions based on vertical space
                     let aspectRatio: CGFloat = 16.0 / 9.0
                     let heightBasedWidth = availableHeight * aspectRatio
                     
                     // Use height-based width if it fits, otherwise use width-based height
                     let width = min(availableWidth, heightBasedWidth)
                     let height = width / aspectRatio
                     
                     MetalView(document.draw2D)
                     .frame(width: width, height: height)
                     .background(Color.black)
                     .cornerRadius(10)
                     }*/
                    
                    Spacer()
                    Divider()
                    
                    CPUView(game: document.game)
                        .frame(maxHeight: 200) // Keep the CPU view smaller in height
                }
                
                Divider()
                
                VStack {
                    if let codeItem = selectedCodeItem {
                        CodeItemListView(
                            codeItem: codeItem,
                            selectedInstruction: $selectedInstruction,
                            selectedInstructionIndex: $selectedInstructionIndex
                        )
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
