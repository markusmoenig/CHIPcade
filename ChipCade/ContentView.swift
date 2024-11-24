//
//  ContentView.swift
//  ChipCade
//
//  Created by Markus Moenig on 28/9/24.
//

import SwiftUI
import MarkdownUI

//enum EditingMode: Int {
//    case list
//    case code
//}

// Hack to avoid UndoManager closure warnings
extension UndoManager: @unchecked @retroactive Sendable { }

struct ContentView: View {
    @Binding var document: ChipCadeDocument

    @EnvironmentObject var appState: AppState

    @State private var selectedCodeItem: CodeItem? = nil
    @State private var selectedImageGroupItem: ImageGroupItem? = nil
    @State private var selectedMemoryItem: MemoryItem? = nil
    @State private var selectedAudioItem: AudioItem? = nil
    @State private var selectedMapItem: MapItem? = nil

    @State private var isPaletteSelected: Bool = false
    @State private var isNotesSelected: Bool = false
    @State private var isSkinSelected: Bool = false
    @State private var isMathLibrarySelected: Bool = false
    @State private var isReferenceSelected: Bool = false

    @State private var referenceText: String = ""

    @State private var selectedInstructionIndex: Int?
    @State private var selectedInstruction: Instruction?

    @State private var selectedImageIndex: Int?

    @AppStorage("editorIsOnLeftSide") private var editorIsOnLeftSide = false

    @State private var searchText: String = ""
    @State private var filteredResults: [(index: Int, instruction: Instruction)] = []
    
    @State private var selectedLayer: Int = 0
    @State private var selectedSprite: Int = 0

    @State private var selectedInfoType: Int = 0

    @State private var infoViewIcon: String = "info.circle.fill"
    @State private var stackViewIcon: String = "square.3.layers.3d"

    @State private var playIcon: String = "play"
    @State private var pauseIcon: String = "playpause"
    @State private var stopIcon: String = "stop.fill"

    @State private var errorInstructionType: InstructionType? = nil

    //@AppStorage("editingMode") private var editingMode: Int = EditingMode.list.rawValue
    //@AppStorage("editingIcon") private var editingIcon: String = "list.bullet.rectangle"
    
    @AppStorage("skinMode") private var skinMode: Bool = true
    @AppStorage("skinIcon") private var skinIcon: String = "cpu.fill"
    
    @AppStorage("noteLine") private var noteLine: Int = 0
    @AppStorage("skinLine") private var skinLine: Int = 0
    @AppStorage("mathLibLine") private var mathLibLine: Int = 0
    @AppStorage("chipRefLine") private var chipRefLine: Int = 0

    @State private var currError: ChipCadeError = .none
    
    //@StateObject private var controllerManager = GameControllerManager()

    @Environment(\.undoManager) var undoManager
    @Environment(\.colorScheme) private var colorScheme: ColorScheme

    var body: some View {
        NavigationView {
            List {
                // Code Section
                CodeSectionView(title: "Code", gameData: $document.game.data, codeItems: $document.game.data.codeItems, selectedCodeItem: $selectedCodeItem)
                
                // Data Section
                MemorySectionView(title: "Data", gameData: $document.game.data, memoryItems: $document.game.data.dataItems, selectedMemoryItem: $selectedMemoryItem)
                
                // Map Section
                MapSectionView(title: "Maps", gameData: $document.game.data, mapItems: $document.game.data.mapItems, selectedMapItem: $selectedMapItem)
                
                // ImageGroup Section
                ImageGroupSectionView(title: "Image Groups", gameData: $document.game.data, imageGroupItems: $document.game.data.imageGroupItems, selectedImageGroupItem: $selectedImageGroupItem)
                
                // Data Section
                AudioSectionView(title: "Audio", gameData: $document.game.data, audioItems: $document.game.data.audioItems, selectedAudioItem: $selectedAudioItem)
                
                #if !os(iOS)
                Divider()
                #endif
                
                if isPaletteSelected {
                    Button(action: {
                        selectedCodeItem = nil
                        selectedImageGroupItem = nil
                        selectedMemoryItem = nil
                        selectedAudioItem = nil
                        selectedMapItem = nil
                        isPaletteSelected = true
                        isNotesSelected = false
                        isReferenceSelected = false
                        isSkinSelected = false
                        isMathLibrarySelected = false
                    }) {
                        HStack {
                            Text("Palette")
                                .foregroundColor(.primary)
                                .padding(.leading, 10)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: {
                        selectedCodeItem = nil
                        selectedImageGroupItem = nil
                        selectedMemoryItem = nil
                        selectedAudioItem = nil
                        selectedMapItem = nil
                        isPaletteSelected = true
                        isNotesSelected = false
                        isReferenceSelected = false
                        isSkinSelected = false
                        isMathLibrarySelected = false
                    }) {
                        HStack {
                            Text("Palette")
                                .foregroundColor(.primary)
                                .padding(.leading, 10)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.borderless)
                }
                
                if isNotesSelected {
                    Button(action: {
                        selectedCodeItem = nil
                        selectedImageGroupItem = nil
                        selectedMemoryItem = nil
                        selectedAudioItem = nil
                        selectedMapItem = nil
                        isPaletteSelected = false
                        isReferenceSelected = false
                        isSkinSelected = false
                        isMathLibrarySelected = false
                        isNotesSelected = true
                        Game.shared.editorMode = .note
                        Game.shared.scriptEditor?.setSessionValue("mainSession", Game.shared.data.notes, noteLine)
                    }) {
                        HStack {
                            Text("Notes")
                                .foregroundColor(.primary)
                                .padding(.leading, 10)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: {
                        selectedCodeItem = nil
                        selectedImageGroupItem = nil
                        selectedMemoryItem = nil
                        selectedAudioItem = nil
                        selectedMapItem = nil
                        isPaletteSelected = false
                        isReferenceSelected = false
                        isSkinSelected = false
                        isMathLibrarySelected = false
                        isNotesSelected = true
                        Game.shared.editorMode = .note
                        Game.shared.scriptEditor?.setSessionValue("mainSession", Game.shared.data.notes, noteLine)
                    }) {
                        HStack {
                            Text("Notes")
                                .foregroundColor(.primary)
                                .padding(.leading, 10)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.borderless)
                }
                
                if isSkinSelected {
                    Button(action: {
                        selectedCodeItem = nil
                        selectedImageGroupItem = nil
                        selectedMemoryItem = nil
                        selectedAudioItem = nil
                        selectedMapItem = nil
                        isPaletteSelected = false
                        isNotesSelected = false
                        isReferenceSelected = false
                        isSkinSelected = true
                        isMathLibrarySelected = false
                        Game.shared.editorMode = .skin
                        Game.shared.scriptEditor?.setSessionValue("mainSession", Game.shared.data.skin, skinLine)
                    }) {
                        HStack {
                            Text("Skin Editor")
                                .foregroundColor(.primary)
                                .padding(.leading, 10)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: {
                        selectedCodeItem = nil
                        selectedImageGroupItem = nil
                        selectedMemoryItem = nil
                        selectedAudioItem = nil
                        selectedMapItem = nil
                        isPaletteSelected = false
                        isNotesSelected = false
                        isReferenceSelected = false
                        isSkinSelected = true
                        isMathLibrarySelected = false
                        Game.shared.editorMode = .skin
                        Game.shared.scriptEditor?.setSessionValue("mainSession", Game.shared.data.skin, skinLine)
                    }) {
                        HStack {
                            Text("Skin Editor")
                                .foregroundColor(.primary)
                                .padding(.leading, 10)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.borderless)
                }
                
                #if !os(iOS)
                Divider()
                #endif
                
                Section(header: Text("Standard").font(.headline)) {
                    if isMathLibrarySelected {
                        Button(action: {
                            selectedCodeItem = nil
                            selectedImageGroupItem = nil
                            selectedMemoryItem = nil
                            selectedAudioItem = nil
                            selectedMapItem = nil
                            isPaletteSelected = false
                            isNotesSelected = false
                            isReferenceSelected = false
                            isSkinSelected = false
                            isMathLibrarySelected = true
                            Game.shared.editorMode = .mathLibrary
                            Game.shared.scriptEditor?.setSessionValue("mainSession", Game.shared.mathSource, mathLibLine)
                        }) {
                            HStack {
                                Text("Math Library")
                                    .foregroundColor(.primary)
                                    .padding(.leading, 10)
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button(action: {
                            selectedCodeItem = nil
                            selectedImageGroupItem = nil
                            selectedMemoryItem = nil
                            selectedAudioItem = nil
                            selectedMapItem = nil
                            isPaletteSelected = false
                            isNotesSelected = false
                            isReferenceSelected = false
                            isSkinSelected = false
                            isMathLibrarySelected = true
                            Game.shared.editorMode = .mathLibrary
                            Game.shared.scriptEditor?.setSessionValue("mainSession", Game.shared.mathSource, mathLibLine)
                        }) {
                            HStack {
                                Text("Math Library")
                                    .foregroundColor(.primary)
                                    .padding(.leading, 10)
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                if isReferenceSelected {
                    Button(action: {
                        selectedCodeItem = nil
                        selectedImageGroupItem = nil
                        selectedMemoryItem = nil
                        selectedAudioItem = nil
                        selectedMapItem = nil
                        isPaletteSelected = false
                        isNotesSelected = false
                        isSkinSelected = false
                        isMathLibrarySelected = false
                        isReferenceSelected = true
                        Game.shared.editorMode = .chipReference
                        Game.shared.scriptEditor?.setSessionValue("mainSession", Game.shared.chipRef, chipRefLine)
                    }) {
                        HStack {
                            Text("Chip Reference")
                                .foregroundColor(.primary)
                                .padding(.leading, 10)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: {
                        selectedCodeItem = nil
                        selectedImageGroupItem = nil
                        selectedMemoryItem = nil
                        selectedAudioItem = nil
                        selectedMapItem = nil
                        isPaletteSelected = false
                        isNotesSelected = false
                        isSkinSelected = false
                        isMathLibrarySelected = false
                        isReferenceSelected = true
                        Game.shared.editorMode = .chipReference
                        Game.shared.scriptEditor?.setSessionValue("mainSession", Game.shared.chipRef, chipRefLine)
                    }) {
                        HStack {
                            Text("Chip Reference")
                                .foregroundColor(.primary)
                                .padding(.leading, 10)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200, maxWidth: 250)
  
            HStack(spacing: 0) {
                
                VStack(spacing: 0) {
                    //Spacer()
                    
                    // Middle Panel
                    createEditorForPanel(rightPanel: false)
                    
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
                    createEditorForPanel(rightPanel: true)
                    
                    Spacer()
//                    Divider()
                    
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
                            Label("", systemImage: stackViewIcon)
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.large)

                        Spacer()
                    }
                    .padding(.bottom, 6)
                        
                    if selectedInfoType == 0 {
                        InstructionInfoView(selectedInstruction: $selectedInstruction, error: $currError, errorInstructionType: $errorInstructionType)
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
                        }
                    })

                    Button("Add Data", action: {
                        document.game.data.addDataItem(named: "Data", length: 1024, using: undoManager) { newItem in
                            selectedMemoryItem = newItem
                        }
                    })
                    
                    Button("Add Map", action: {
                        document.game.data.addMapItem(named: "New Map", using: undoManager) { newItem in
                            selectedMapItem = newItem
                        }
                    })
                    
                    Button("Add Image Group", action: {
                        document.game.data.addImageGroupItem(named: "New Image Group", using: undoManager) { newItem in
                            selectedImageGroupItem = newItem
                        }
                    })

                    Button("Add Audio...", action: {
                        openAudioFilePicker { url, filenameWithoutExtension in
                            if let url = url, let filename = filenameWithoutExtension {
                                if let audioData: Data = try? Data(contentsOf: url) {
                                    document.game.data.addAudioItem(named: filename, data: audioData, using: undoManager) { newItem in
                                        selectedAudioItem = newItem
                                    }
                                }
                            }
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
                    pauseIcon = "playpause"
                    stopIcon = "stop"
                }) {
                    Label("Play", systemImage: playIcon)
                }
                .keyboardShortcut("R")

                Button(action: {
                    document.game.step()
                    playIcon = "play"
                    pauseIcon = "playpause.fill"
                    stopIcon = "stop"
                }) {
                    Label("Step", systemImage: pauseIcon)
                }
                
                Button(action: {
                    document.game.stop()
                    playIcon = "play"
                    pauseIcon = "playpause"
                    stopIcon = "stop.fill"
                }) {
                    Label("Stop", systemImage: stopIcon)
                }
                
                Spacer()
                
                Button(action: {
                    editorIsOnLeftSide.toggle()
//                    if editorIsOnLeftSide {
//                        editingMode = EditingMode.code.rawValue
//                        editingIcon = "list.bullet.rectangle.fill"
//                    }
                }) {
                    Label("Swap Views", systemImage: "rectangle.2.swap")
                }
                
                Spacer()

                 /*
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
                }*/
                
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

                Button(action: {
                    Game.shared.reset()
                    Game.shared.cpuRender.update()
                }) {
                    Label("Reset CPU", systemImage: "power.circle")
                }
            }
        }
        .onAppear {
            selectedCodeItem = document.game.data.codeItems[0]
            
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
            
            // Set the current line numbers
            Game.shared.noteLine = noteLine
            Game.shared.skinLine = skinLine
            Game.shared.mathLibLine = mathLibLine
            Game.shared.chipRefLine = chipRefLine
        }
        
        // When the code changes in the code editor, compile it
        .onReceive(document.game.codeTextChanged) { value in
            if Game.shared.editorMode == .note {
                Game.shared.data.notes = value
            } else
            if !isSkinSelected {
                compile(string: value)
            } else if isSkinSelected {
                Game.shared.skin.compile(text: Game.shared.data.skin)
                Game.shared.cpuRender.update()
            }
        }
        
        // The cursor has changed in the codeEditor
        .onReceive(document.game.codeLineChanged) { line in
            if Game.shared.editorMode == .code {
                if document.game.currCodeItemIndex != MathLibraryIndex {
                    if line < document.game.data.codeItems[document.game.currCodeItemIndex].codes.count {
                        document.game.currInstructionIndex = line
                        selectedInstruction = document.game.data.codeItems[document.game.currCodeItemIndex].codes[document.game.currInstructionIndex]
                        selectedInstructionIndex = document.game.currInstructionIndex
                    }
                }
            } else
            if Game.shared.editorMode == .note {
                Game.shared.noteLine = line + 1
                noteLine = line + 1
            } else
            if Game.shared.editorMode == .skin {
                Game.shared.skinLine = line + 1
                skinLine = line + 1
            } else
            if Game.shared.editorMode == .mathLibrary {
                Game.shared.mathLibLine = line + 1
                mathLibLine = line + 1
            } else
            if Game.shared.editorMode == .chipReference {
                Game.shared.chipRefLine = line + 1
                chipRefLine = line + 1
            }
        }
        
        // Error state has changed
        .onReceive(document.game.errorChanged) { error in
            currError = error
            if  document.game.errorCodeItemIndex < document.game.data.codeItems.count {
                if error != .none {
                    selectedCodeItem = document.game.data.codeItems[document.game.errorCodeItemIndex]
                    selectedInstruction = document.game.data.codeItems[document.game.errorCodeItemIndex].codes[document.game.errorInstructionIndex]
                    selectedInstructionIndex = document.game.errorInstructionIndex
                }
                else {
                    if document.game.currCodeItemIndex == MathLibraryIndex {
                        if !isMathLibrarySelected {
                            selectedCodeItem = nil
                            Game.shared.editorMode = .mathLibrary
                            isMathLibrarySelected = true
                        }
                        mathLibLine = document.game.currInstructionIndex
                    } else {
                        selectedCodeItem = document.game.data.codeItems[document.game.currCodeItemIndex]
                        
                        if document.game.currInstructionIndex >= document.game.data.codeItems[document.game.currCodeItemIndex].codes.count {
                            document.game.currInstructionIndex = 0
                        }
                        
                        selectedInstruction = document.game.data.codeItems[document.game.currCodeItemIndex].codes[document.game.currInstructionIndex]
                        selectedInstructionIndex = document.game.currInstructionIndex
                    }
                }
            }
            
            if Game.shared.stepped {
                Game.shared.syncEditor()
                if Game.shared.editorMode == .code {
                    Game.shared.scriptEditor?.sessionGotoLine("MainSession", selectedInstructionIndex! + 1)
                } else
                if Game.shared.editorMode == .mathLibrary {
                    Game.shared.scriptEditor?.sessionGotoLine("MainSession", mathLibLine + 1)
                }
            }
            Game.shared.stepped = false
        }
        
        // Error state has changed
        .onReceive(document.game.breakpoint) { _ in
            playIcon = "play"
            pauseIcon = "playpause.fill"
            stopIcon = "stop"
        }
        
        .onChange(of: appState.showHelpReference) {
            selectedCodeItem = nil
            selectedImageGroupItem = nil
            selectedMemoryItem = nil
            selectedAudioItem = nil
            selectedMapItem = nil
            isPaletteSelected = false
            isNotesSelected = false
            isSkinSelected = false
            isReferenceSelected = true
            isMathLibrarySelected = false
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
        
        .onChange(of: selectedCodeItem) {
            if let selectedCodeItem = selectedCodeItem {
                if let index = document.game.getCodeItemIndex(byItem: selectedCodeItem) {
                    document.game.currCodeItemIndex = index
                }
                
                if let editor = Game.shared.scriptEditor {
                    editor.setSessionValue("mainSession", selectedCodeItem.source, selectedCodeItem.currLine)
                }
                
                document.game.currInstructionIndex = 0
                selectedInstructionIndex = 0
                
                selectedImageGroupItem = nil
                selectedMemoryItem = nil
                selectedAudioItem = nil
                selectedMapItem = nil
                isPaletteSelected = false
                isNotesSelected = false
                isSkinSelected = false
                isReferenceSelected = false
                isMathLibrarySelected = false
                Game.shared.editorMode = .code
            }
        }
        
        .onChange(of: selectedImageGroupItem) {
            if selectedImageGroupItem != nil {
                selectedCodeItem = nil
                selectedMemoryItem = nil
                selectedAudioItem = nil
                selectedMapItem = nil
                isPaletteSelected = false
                isNotesSelected = false
                isSkinSelected = false
                isMathLibrarySelected = false
                isReferenceSelected = false
            }
        }
        
        .onChange(of: selectedMemoryItem) {
            if selectedMemoryItem != nil {
                selectedCodeItem = nil
                selectedImageGroupItem = nil
                selectedAudioItem = nil
                selectedMapItem = nil
                isPaletteSelected = false
                isNotesSelected = false
                isSkinSelected = false
                isMathLibrarySelected = false
                isReferenceSelected = false
            }
        }
        
        .onChange(of: selectedMapItem) {
            if let selectedMapItem = selectedMapItem {
                selectedCodeItem = nil
                selectedImageGroupItem = nil
                selectedAudioItem = nil
                selectedMemoryItem = nil
                isPaletteSelected = false
                isNotesSelected = false
                isSkinSelected = false
                isMathLibrarySelected = false
                isReferenceSelected = false
                Game.shared.currMapIndex = Game.shared.getMapItemIndex(byItem: selectedMapItem)
            } else {
                Game.shared.currMapIndex = nil
            }
        }
        
        .onChange(of: selectedAudioItem) {
            if selectedAudioItem != nil {
                selectedCodeItem = nil
                selectedImageGroupItem = nil
                selectedMemoryItem = nil
                selectedMapItem = nil
                isPaletteSelected = false
                isNotesSelected = false
                isSkinSelected = false
                isMathLibrarySelected = false
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
    
    /// Create the
    private func createEditorForPanel(rightPanel: Bool) -> some View {
        @ViewBuilder
        var view: some View {
            
            if let selectedMapItem = selectedMapItem {
                
                if !rightPanel {
                    MetalView(document.game, .Map)
                }
                
            } else            
            if editorIsOnLeftSide != rightPanel {
                if selectedCodeItem != nil {
                    // Display WebView when a code item is selected
                    WebView(colorScheme)
                } else if isSkinSelected {
                    // Display WebView for Skin Editor
                    WebView(colorScheme)
                } else if let imageGroupItem = selectedImageGroupItem {
                    // Display ImageGroupItemListView
                    ImageGroupItemListView(imageGroupItem: imageGroupItem, selectedImageIndex: $selectedImageIndex)
                } else if let memoryItem = selectedMemoryItem {
                    // Display MemoryGridView
                    MemoryGridView(memoryItem: memoryItem)
                } else if let audioItem = selectedAudioItem {
                    // Display AudioInfoView
                    AudioInfoView(audioItem: audioItem)
                } else if isPaletteSelected {
                    // Display PaletteView
                    PaletteView(game: document.game)
                        .padding(0)
                } else if isNotesSelected {
                    // Display WebView for Notes
                    WebView(colorScheme)
                } else if isReferenceSelected {
                    // Display WebView for Reference
                    WebView(colorScheme)
                } else if isMathLibrarySelected {
                    // Display WebView for Math Library
                    WebView(colorScheme)
                }
            } else {
                // Display MetalView for the game
                MetalView(document.game, .Game)
            }
        }

        return view
    }
    
    private func openAudioFilePicker(completion: @escaping (URL?, String?) -> Void) {
        let panel = NSOpenPanel()
        panel.title = "Select an Audio File"
        panel.allowedContentTypes = [.wav, .mp3] // Specify allowed types
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            let filenameWithoutExtension = url.deletingPathExtension().lastPathComponent
            completion(url, filenameWithoutExtension)
        } else {
            completion(nil, nil) // User canceled or no file selected
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
    func compile(string: String) {
        //guard editingMode == EditingMode.code.rawValue else { return }
        
        if let codeItem = selectedCodeItem {

            var instructions = [Instruction]()
            codeItem.source = string

            Game.shared.errorInstructionType = nil
            let errorLine : Int? = Game.shared.compile(string:  string, instructions: &instructions)
            
            errorInstructionType = Game.shared.errorInstructionType
            
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
