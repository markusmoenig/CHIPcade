//
//  ContentView.swift
//  ChipCade
//
//  Created by Markus Moenig on 28/9/24.
//

import SwiftUI

// Hack to avoid UndoManager closure warnings
extension UndoManager: @unchecked @retroactive Sendable { }

struct ContentView: View {
    @Binding var document: ChipCadeDocument

    @State private var selectedCodeItem: CodeItem? = nil
    @State private var selectedImageGroupItem: ImageGroupItem? = nil
    @State private var selectedMemoryItem: MemoryItem? = nil

    @State private var isPaletteSelected: Bool = false
    @State private var isNotesSelected: Bool = false
    @State private var isReferenceSelected: Bool = false

    @State private var notes: String = ""
    @State private var referenceText: String = ""

    @State private var selectedInstructionIndex: Int?
    @State private var selectedInstruction: Instruction?

    @State private var selectedImageIndex: Int?

    @State private var showingAddMemoryItemPopover = false

    @State private var previewIsLeftSide = false

    @State private var searchText: String = ""
    @State private var filteredResults: [(index: Int, instruction: Instruction)] = []
    
    @State private var selectedLayer: Int = 0
    @State private var selectedSprite: Int = 0
    
    @Environment(\.undoManager) var undoManager

    var body: some View {
        NavigationView {
            List {
                // Code Section
                CodeSectionView(title: "Code", gameData: $document.game.data, codeItems: $document.game.data.codeItems, selectedCodeItem: $selectedCodeItem, selectedMemoryItem: $selectedMemoryItem, selectedImageGroupItem: $selectedImageGroupItem)
                
                // ImageGroup Section
                ImageGroupSectionView(title: "Image Groups", gameData: $document.game.data, imageGroupItems: $document.game.data.imageGroupItems, selectedImageGroupItem: $selectedImageGroupItem, selectedMemoryItem: $selectedMemoryItem, selectedCodeItem: $selectedCodeItem)
                
                // Data Section
                MemorySectionView(title: "Data", gameData: $document.game.data, memoryItems: $document.game.data.dataItems, selectedMemoryItem: $selectedMemoryItem, selectedCodeItem: $selectedCodeItem, selectedImageGroupItem: $selectedImageGroupItem)
                
                #if !os(iOS)
                Divider()
                #endif
                
                Button(action: {
                    selectedCodeItem = nil
                    selectedImageGroupItem = nil
                    selectedMemoryItem = nil
                    isPaletteSelected = true
                    isNotesSelected = false
                    isReferenceSelected = false
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
                            .fill((isPaletteSelected) ? Color.accentColor.opacity(0.2) : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    selectedCodeItem = nil
                    selectedImageGroupItem = nil
                    selectedMemoryItem = nil
                    isPaletteSelected = false
                    isNotesSelected = true
                    isReferenceSelected = false
                }) {
                    HStack {
                        Text("Notes")
                            .foregroundColor(.primary)
                            .padding(.leading, 10)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill((isNotesSelected) ? Color.accentColor.opacity(0.2) : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                #if !os(iOS)
                Divider()
                #endif
                
                Button(action: {
                    selectedCodeItem = nil
                    selectedImageGroupItem = nil
                    selectedMemoryItem = nil
                    isPaletteSelected = false
                    isNotesSelected = false
                    isReferenceSelected = true
                }) {
                    HStack {
                        Text("Reference")
                            .foregroundColor(.primary)
                            .padding(.leading, 10)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill((isReferenceSelected) ? Color.accentColor.opacity(0.2) : Color.clear)
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
                        MetalView(document.game, .Game)
                    }
                    
                    Spacer()
                    
                    /*
                    // Toolbar for selecting layer and sprite
                    HStack {
                        // Menu for Layer Selection
                        Menu {
                            ForEach(0..<8, id: \.self) { layer in
                                Button(action: {
                                    selectedLayer = layer
                                }) {
                                    Text("Layer \(layer)")
                                }
                            }
                        } label: {
                            Label("Select Layer: \(selectedLayer)", systemImage: "square.stack.3d.up.fill")
                        }
                        .frame(maxWidth: 200)
                        //.buttonStyle(PlainButtonStyle)

                        // TextField for Sprite Selection
                        TextField("Sprite ID", value: $selectedSprite, formatter: NumberFormatter())
                            .frame(maxWidth: 100)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            //.keyboardType(.numberPad)  // You can set number pad for easier input
                        
                        Spacer()
                    }
                    //.padding()
                    */
                    
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
                            MetalView(document.game, .Game)
                        }
                    } else
                    if let imageGroupItem = selectedImageGroupItem {
                        ImageGroupItemListView(imageGroupItem: imageGroupItem, selectedImageIndex: $selectedImageIndex)
                    } else
                    if let memoryItem = selectedMemoryItem {
                        MemoryGridView(memoryItem: memoryItem)
                    } else if isPaletteSelected {
                        PaletteView(game: document.game)
                            .padding(0)
                    } else if isNotesSelected {
                        TextEditor(text: $notes)
                            .padding(4)
                    } else if isReferenceSelected {
                        ScrollView {
                            Text(.init(referenceText))
                                .padding(4)
                        }
                    }
                    
                    Spacer()
                    Divider()
                        
                    StackView(game: document.game)
                        .frame(height: 150)
                }
                .frame(maxWidth: 350)
            }
        }        
        .toolbar {
            
            ToolbarItem(placement: .navigation) {
                Menu {
                    
                    Button("Add Code Module", action: {
                        document.game.data.addCodeItem(named: "New Code Module", using: undoManager) { newItem in
                            selectedCodeItem = newItem
                            selectedMemoryItem = nil
                            selectedImageGroupItem = nil
                        }
                    })
                    
                    Button("Add Image Group", action: {
                        document.game.data.addImageGroupItem(named: "New Image Group", using: undoManager) { newItem in
                            selectedImageGroupItem = newItem
                            selectedCodeItem = nil
                            selectedMemoryItem = nil
                        }
                    })
                    
                    Button("Add Raw Data", action: {
                        document.game.data.addDataItem(named: "Data", length: 1024, using: undoManager) { newItem in
                            selectedMemoryItem = newItem
                            selectedCodeItem = nil
                            selectedImageGroupItem = nil
                        }
                    })
                }
                label: {
                    Label("Add", systemImage: "plus")
                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                
                Button(action: {
                    document.game.play()
                }) {
                    Label("Play", systemImage: "play.fill")
                }
                .keyboardShortcut("R")

                Button(action: {
                    document.game.executeInstruction()
                    document.game.currInstructionIndex += 1
                    selectedInstructionIndex = document.game.currInstructionIndex
                    document.game.cpuRender.update()
                }) {
                    Label("Step", systemImage: "playpause")
                }
                
                Button(action: {
                    document.game.stop()
                }) {
                    Label("Stop", systemImage: "stop.fill")
                }
                
                Spacer()
                
                Button(action: {
                    previewIsLeftSide.toggle()
                }) {
                    Label("Swap", systemImage: "rectangle.2.swap")
                }
                
                Spacer()

                // Toolbar button for adding a new MemoryItem
//                Button(action: {
//                    showingAddMemoryItemPopover.toggle() // Toggle popover visibility
//                }) {
//                    Label("Add Memory Item", systemImage: "plus")
//                }
//                .popover(isPresented: $showingAddMemoryItemPopover) {
//                    AddMemoryItemView(game: document.game, selectedMemoryItem: $selectedMemoryItem)
//                }
            }
        }
        .onAppear {
            selectedCodeItem = document.game.data.codeItems[0]
            notes = document.game.data.notes
            
            if let fileURL = Bundle.main.url(forResource: "ChipDocumentation", withExtension: "md") {
                do {
                    let data = try Data(contentsOf: fileURL)
                    if let fileContents = String(data: data, encoding: .utf8) {
                        referenceText = fileContents
                    } else {
                        referenceText = "Failed to decode the file contents."
                    }
                } catch {
                    referenceText = "Failed to load reference document: \(error.localizedDescription)"
                }
            } else {
                referenceText = "Reference document not found."
            }
        }
        
        .onReceive(document.game.errorChanged) { value in
            if value {
                selectedCodeItem = document.game.data.codeItems[document.game.errorCodeItemIndex]
                selectedInstruction = document.game.data.codeItems[document.game.errorCodeItemIndex].codes[document.game.errorInstructionIndex]
                selectedInstructionIndex = document.game.errorInstructionIndex
            } else {
                selectedCodeItem = document.game.data.codeItems[document.game.currCodeItemIndex]
                selectedInstruction = document.game.data.codeItems[document.game.currCodeItemIndex].codes[document.game.currInstructionIndex]
                selectedInstructionIndex = document.game.currInstructionIndex
            }
            selectedImageGroupItem = nil
            selectedMemoryItem = nil
        }
        
        .onChange(of: selectedInstructionIndex) {
            if let selectedInstructionIndex = selectedInstructionIndex {
                document.game.currInstructionIndex = selectedInstructionIndex
            }
            document.game.cpuRender.update()
        }
        
        .onChange(of: notes) {
            document.game.data.notes = notes
        }
        
        .onChange(of: selectedCodeItem) {
            if let selectedCodeItem = selectedCodeItem {
                if let index = document.game.getCodeItemIndex(byItem: selectedCodeItem) {
                    document.game.currCodeItemIndex = index
                }
            }
            document.game.currInstructionIndex = 0
            selectedInstructionIndex = 0
            document.game.selectionState = .code
        }
        
        .onChange(of: selectedCodeItem) {
            if selectedCodeItem != nil {
                isPaletteSelected = false
                isNotesSelected = false
                isReferenceSelected = false
            }
        }
        
        .onChange(of: selectedMemoryItem) {
            if selectedMemoryItem != nil {
                isPaletteSelected = false
                isNotesSelected = false
                isReferenceSelected = false
            }
        }
        
        .onChange(of: selectedImageGroupItem) {
            if selectedImageGroupItem != nil {
                isPaletteSelected = false
                isNotesSelected = false
                isReferenceSelected = false
            }
        }
        
        .searchable(text: $searchText) {
            ForEach(searchResults, id: \.self) { result in
                Text("\(result)").searchCompletion(result)
            }
        }
    }
    
    var searchResults: [String] {
        var results : [String] = []

        let query = searchText.lowercased()
        
        for codeItem in document.game.data.codeItems {
            for (_, instruction) in codeItem.codes.enumerated() {
//                if instruction.meta.tag.lowercased().contains(query.lowercased()) {
//                    results.append(instruction.meta.tag.lowercased())
//                }
            }
        }
        
        //document.model.searchResultsChanged.send(results)
        return results
    }
}

struct AddMemoryItemView: View {
    @ObservedObject var game: Game
    @Binding var selectedMemoryItem: MemoryItem?
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = "New Memory Item"
    //@State private var selectedType: MemoryType = .code
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
                
//                Picker("Type", selection: $selectedType) {
//                    Text("Code").tag(MemoryType.code)
//                    Text("Sprite").tag(MemoryType.sprite)
//                    Text("Data").tag(MemoryType.data)
//                }
//                .pickerStyle(SegmentedPickerStyle())
//                .padding(.bottom, 10)
                
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
        //let newItem = MemoryItem(name: name, length: length)
        //let newCodeItem = CodeItem(name: name)

        // Add the new memory item to the appropriate section
//        switch selectedType {
//        case .code:
//            game.data.codeItems.append(newCodeItem)
//        case .sprite:
//            game.data.spriteItems.append(newItem)
//        case .data:
//            game.data.dataItems.append(newItem)
//        }

        // Automatically select the new memory item
        //selectedMemoryItem = newItem
    }
}

#Preview {
    ContentView(document: .constant(ChipCadeDocument()))
}
