//
//  ContentView.swift
//  ChipCade
//
//  Created by Markus Moenig on 28/9/24.
//

import SwiftUI
import MarkdownUI

enum EditingMode: Int {
    case list
    case code
}

// Hack to avoid UndoManager closure warnings
extension UndoManager: @unchecked @retroactive Sendable { }

struct ContentView: View {
    @Binding var document: ChipCadeDocument

    @EnvironmentObject var appState: AppState

    @State private var selectedCodeItem: CodeItem? = nil
    @State private var selectedImageGroupItem: ImageGroupItem? = nil
    @State private var selectedMemoryItem: MemoryItem? = nil

    @State private var isPaletteSelected: Bool = false
    @State private var isNotesSelected: Bool = false
    @State private var isSkinSelected: Bool = false
    @State private var isReferenceSelected: Bool = false

    @State private var notes: String = ""
    @State private var referenceText: String = ""

    @State private var selectedInstructionIndex: Int?
    @State private var selectedInstruction: Instruction?

    @State private var selectedImageIndex: Int?

    @State private var showingAddMemoryItemPopover = false

    @AppStorage("editorIsOnLeftSide") private var editorIsOnLeftSide = false

    @State private var searchText: String = ""
    @State private var filteredResults: [(index: Int, instruction: Instruction)] = []
    
    @State private var selectedLayer: Int = 0
    @State private var selectedSprite: Int = 0

    @State private var selectedInfoType: Int = 0

    @State private var infoViewIcon: String = "info.circle.fill"
    @State private var stackViewIcon: String = "square.3.layers.3d"

    @State private var playIcon: String = "play"
    @State private var stopIcon: String = "stop.fill"

    @AppStorage("editingMode") private var editingMode: Int = EditingMode.list.rawValue
    @AppStorage("editingIcon") private var editingIcon: String = "list.bullet.rectangle"
    
    @AppStorage("skinMode") private var skinMode: Bool = true
    @AppStorage("skinIcon") private var skinIcon: String = "cpu.fill"
    
    @State private var currError: ChipCadeError = .none
    
    //@StateObject private var controllerManager = GameControllerManager()

    @Environment(\.undoManager) var undoManager
    @Environment(\.colorScheme) private var colorScheme: ColorScheme

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
                    isSkinSelected = false
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
                    isSkinSelected = false
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
                
                Button(action: {
                    selectedCodeItem = nil
                    selectedImageGroupItem = nil
                    selectedMemoryItem = nil
                    isPaletteSelected = false
                    isNotesSelected = false
                    isReferenceSelected = false
                    isSkinSelected = true
                    Game.shared.skinMode = true
                    Game.shared.scriptEditor?.setSessionValue("mainSession", Game.shared.data.skin, 0)
                }) {
                    HStack {
                        Text("Skin Editor")
                            .foregroundColor(.primary)
                            .padding(.leading, 10)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill((isSkinSelected) ? Color.accentColor.opacity(0.2) : Color.clear)
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
                    isSkinSelected = false
                }) {
                    HStack {
                        Text("Chip Reference")
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
                    //Spacer()
                    
                    // Middle Panel
                    
                    if editorIsOnLeftSide == true {
                        if let codeItem = selectedCodeItem {
                            if editorIsOnLeftSide {
                                if editingMode == EditingMode.list.rawValue {
                                    CodeItemListView(
                                        codeItem: codeItem,
                                        selectedInstruction: $selectedInstruction,
                                        selectedInstructionIndex: $selectedInstructionIndex
                                    )
                                } else {
                                    WebView(colorScheme)
                                }
                            }
                        } else if isSkinSelected {
                            WebView(colorScheme)
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
                                Markdown(referenceText)
                                    .padding(4)
                            }
                        }
                    } else {
                        MetalView(document.game, .Game)
                    }
                    
                    //Spacer()
                    
                    if skinMode {
                        Divider()
                        
                        MetalView(document.game, .CPU)
                            .frame(maxHeight: 250)
                    }
                }
                
                Divider()
                
                VStack(spacing: 0) {
                    
                    // Right Panel
                    
                    if !editorIsOnLeftSide {
                        if let codeItem = selectedCodeItem {
                            if editingMode == EditingMode.list.rawValue {
                                CodeItemListView(
                                    codeItem: codeItem,
                                    selectedInstruction: $selectedInstruction,
                                    selectedInstructionIndex: $selectedInstructionIndex
                                )
                            } else {
                                WebView(colorScheme)
                            }
                        } else if isSkinSelected {
                            WebView(colorScheme)
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
                                Markdown(referenceText)
                                    .padding(4)
                            }
                        }
                    } else {
                        MetalView(document.game, .Game)
                    }
                    
                    Spacer()
                    //Divider()
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            selectedInfoType = 0
                            infoViewIcon = "info.circle.fill"
                            stackViewIcon = "square.3.layers.3d"
                        }) {
                            Label("", systemImage: infoViewIcon)
                        }
                        .buttonStyle(.borderless)
                        .padding(.leading, 8)
                        .controlSize(.large)

                        Button(action: {
                            selectedInfoType = 1
                            infoViewIcon = "info.circle"
                            stackViewIcon = "square.3.layers.3d.top.filled"
                        }) {
                            Label("", systemImage: "square.3.layers.3d")
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.large)

                        Spacer()
                    }
                    .padding(.bottom, 6)
                        
                    if selectedInfoType == 0 {
                        InstructionInfoView(selectedInstruction: $selectedInstruction, error: $currError)
                            .frame(maxHeight: 100)
                    } else {
                        StackView(game: document.game)
                            .frame(maxHeight: 100)
                    }
                }
                #if os(macOS)
                .frame(maxWidth: 350)
                #elseif os(iOS)
                .frame(maxWidth: 400)
                #endif
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
                    playIcon = "play.fill"
                    stopIcon = "stop"
                }) {
                    Label("Play", systemImage: playIcon)
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
                    playIcon = "play"
                    stopIcon = "stop.fill"
                }) {
                    Label("Stop", systemImage: stopIcon)
                }
                
                Spacer()
                
                Button(action: {
                    editorIsOnLeftSide.toggle()
                    if editorIsOnLeftSide {
                        editingMode = EditingMode.code.rawValue
                        editingIcon = "list.bullet.rectangle.fill"
                    }
                }) {
                    Label("Swap Views", systemImage: "rectangle.2.swap")
                }
                
                Button(action: {
                    if editingMode == EditingMode.list.rawValue {
                        editingMode = EditingMode.code.rawValue
                        editingIcon = "list.bullet.rectangle.fill"
                    } else {
                        editingMode = EditingMode.list.rawValue
                        editingIcon = "list.bullet.rectangle"
                    }
                }) {
                    Label("Editing Mode", systemImage: editingIcon)
                }
                
                Button(action: {
                    if skinMode {
                        skinMode = false
                        skinIcon = "cpu"
                    } else {
                        skinMode = true
                        skinIcon = "cpu.fill"

                    }
                }) {
                    Label("CPU Skin", systemImage: skinIcon)
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
            
            if let fileURL = Bundle.main.url(forResource: "ChipReference", withExtension: "md") {
                do {
                    let data = try Data(contentsOf: fileURL)
                    if let fileContents = String(data: data, encoding: .utf8) {
                        referenceText = fileContents
                    }
                } catch {
                    referenceText = "Failed to load reference document: \(error.localizedDescription)"
                }
            } else {
                referenceText = "Reference document not found."
            }
            #if os(macOS)
            document.game.play(initOnly: true)            
            #endif
            document.game.skin.compile(text: document.game.data.skin)
            Game.shared.scriptEditor?.setTheme(colorScheme)
        }
        
        // When the code changes in the code editor, compile it
        .onReceive(document.game.codeTextChanged) { _ in
            if !isSkinSelected {
                compile()
            } else {
                Game.shared.skin.compile(text: Game.shared.data.skin)
                Game.shared.cpuRender.update()
            }
        }
        
        // The cursor has changed in the codeEditor
        .onReceive(document.game.codeLineChanged) { line in
            if line < document.game.data.codeItems[document.game.currCodeItemIndex].codes.count {
                document.game.currInstructionIndex = line
                selectedInstruction = document.game.data.codeItems[document.game.currCodeItemIndex].codes[document.game.currInstructionIndex]
                selectedInstructionIndex = document.game.currInstructionIndex
            }
        }
        
        // Error state has changed
        .onReceive(document.game.errorChanged) { error in
            currError = error
            if error != .none {
                selectedCodeItem = document.game.data.codeItems[document.game.errorCodeItemIndex]
                selectedInstruction = document.game.data.codeItems[document.game.errorCodeItemIndex].codes[document.game.errorInstructionIndex]
                selectedInstructionIndex = document.game.errorInstructionIndex
            }
            else {
                selectedCodeItem = document.game.data.codeItems[document.game.currCodeItemIndex]
                
                if document.game.currInstructionIndex >= document.game.data.codeItems[document.game.currCodeItemIndex].codes.count {
                    document.game.currInstructionIndex = 0
                }
                
                selectedInstruction = document.game.data.codeItems[document.game.currCodeItemIndex].codes[document.game.currInstructionIndex]
                selectedInstructionIndex = document.game.currInstructionIndex
            }
            selectedImageGroupItem = nil
            selectedMemoryItem = nil
        }
        
        .onChange(of: appState.showHelpReference) {
            selectedCodeItem = nil
            selectedImageGroupItem = nil
            selectedMemoryItem = nil
            isPaletteSelected = false
            isNotesSelected = false
            isSkinSelected = false
            isReferenceSelected = true
        }
        
        .onChange(of: selectedInstructionIndex) {
            if let selectedInstructionIndex = selectedInstructionIndex {
                if let codeItem = selectedCodeItem {
                    if let codeItemIndex = document.game.getCodeItemIndex(byItem: codeItem) {
                        document.game.currCodeItemIndex = codeItemIndex
                        document.game.currInstructionIndex = selectedInstructionIndex
                        selectedInstruction = document.game.getInstruction()
                    }
                    codeItem.currLine = selectedInstructionIndex + 1
                }
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
                
                let codeText = selectedCodeItem.codes.map { $0.format() }.joined(separator: "\n")
                Game.shared.currentCodeItemText = codeText
                if let editor = Game.shared.scriptEditor {
                    editor.setSessionValue("mainSession", codeText, selectedCodeItem.currLine)
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
                isSkinSelected = false
                isReferenceSelected = false
                Game.shared.skinMode = false
            }
        }
        
        .onChange(of: selectedMemoryItem) {
            if selectedMemoryItem != nil {
                isPaletteSelected = false
                isNotesSelected = false
                isSkinSelected = false
                isReferenceSelected = false
            }
        }
        
        .onChange(of: selectedImageGroupItem) {
            if selectedImageGroupItem != nil {
                isPaletteSelected = false
                isNotesSelected = false
                isSkinSelected = false
                isReferenceSelected = false
            }
        }
        
        .onChange(of: colorScheme) {
            Game.shared.scriptEditor?.setTheme(colorScheme)
            Game.shared.skin.compile(text: Game.shared.data.skin)
            Game.shared.cpuRender.update()
        }
        
        .searchable(text: $searchText, prompt: "Search tags") {
            ForEach(searchResults, id: \.self) { result in
                Text("\(result)").searchCompletion(result)
                .onTapGesture {
                    // For mouse clicks
                    if let (codeItemIndex, instructionIndex) = Game.shared.data.getCodeAddress(name: result, currentCodeIndex: Game.shared.currCodeItemIndex) {
                        selectedCodeItem = Game.shared.data.codeItems[codeItemIndex]
                        selectedInstructionIndex = instructionIndex
                    }
                }
                .onSubmit(of: .search) {
                    // For keyboard selection
                    if let (codeItemIndex, instructionIndex) = Game.shared.data.getCodeAddress(name: result, currentCodeIndex: Game.shared.currCodeItemIndex) {
                        selectedCodeItem = Game.shared.data.codeItems[codeItemIndex]
                        selectedInstructionIndex = instructionIndex
                    }
                }
            }
        }
    }
    
    var searchResults: [String] {
        var results : [String] = []

        let query = searchText.lowercased()
        
        for codeItem in document.game.data.codeItems {
            for (_, instruction) in codeItem.codes.enumerated() {
                if instruction.type == .tag {
                    if instruction.memory!.lowercased().contains(query.lowercased()) {
                        results.append("\(codeItem.name).\(instruction.memory!)")
                    }
                }
            }
        }
        return results
    }
    
    // The codeText has changed in .code editing mode, we have to compile back into Instructions
    func compile() {
        guard editingMode == EditingMode.code.rawValue else { return }
        
        if let codeItem = selectedCodeItem {

            var instructions = [Instruction]()
            let lines = Game.shared.currentCodeItemText.split(separator: "\n", omittingEmptySubsequences: false)
            
            var errorLine : Int? = nil
            
            for (index, line) in lines.enumerated() {
                // If line is empty, treat it as NOP
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    instructions.append(Instruction(.nop))
                    continue
                }
                
                // Check if the line is a tag (ends with ':')
                if line.hasSuffix(":") {
                    let tagName = String(line.dropLast()) // Remove the colon
                    
                    // Validate the tag name
                    if tagName.isEmpty || tagName.contains(" ") || tagName.first?.isNumber == true {
                        errorLine = index
                        break
                    }
                    
                    // Create the tag instruction
                    let instruction = Instruction(.tag)
                    instruction.memory = tagName
                    //print(instruction.format())
                    instructions.append(instruction)
                    continue
                }
                
                if let instruction = Instruction.fromString(String(line)) {
                    //print(instruction.format())
                    instructions.append(instruction)
                } else {
                    print("Error: \(String(line))")
                    errorLine = index
                    break;
                }
            }
            
            if let errorLine {
                selectedInstructionIndex = errorLine
                if let codeItemIndex = document.game.getCodeItemIndex(byItem: codeItem) {
                    document.game.error = .syntaxError
                    document.game.errorCodeItemIndex = codeItemIndex
                    document.game.errorInstructionIndex = errorLine
                    document.game.errorChanged.send(.syntaxError)
                }
            } else {
                selectedCodeItem = nil
                selectedCodeItem = codeItem
                codeItem.codes = instructions
                document.game.error = .none
                document.game.errorChanged.send(.none)
            }
        }
    }
}

#Preview {
    ContentView(document: .constant(ChipCadeDocument()))
}
