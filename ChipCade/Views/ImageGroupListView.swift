//
//  ImageGroupItemListView.swift
//  CHIPcade
//
//  Created by Markus Moenig on 7/10/24.
//

import SwiftUI

struct ImageGroupItemListView: View {
    @ObservedObject var imageGroupItem: ImageGroupItem
    @Binding var selectedImageIndex: Int?
    @Binding var isGridView: Bool
    
    @State private var selectedTilemapData: Data? = nil
    @State private var isTileSizePromptPresented = false
    @State private var tileSize: CGFloat = 24

    var body: some View {
        VStack {
            HStack {
                
                Button(action: {
                    isGridView.toggle()
                }) {
                    Image(systemName: isGridView ? "square.grid.2x2" : "list.bullet")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .padding(.leading, 8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()

                Button(action: {
                    #if os(macOS)
                    openFileDialogMacOS()
                    #elseif os(iOS)
                    openFileDialogiOS()
                    #endif
                }) {
                    Label("Add Image", systemImage: "plus")
                }
                .padding()

                Button(action: {
                    openTilemapDialog()
                }) {
                    Label("Add Tilemap", systemImage: "square.grid.3x3.fill")
                }
                .padding()
                
                Spacer()
            }

            // Switch between List and Grid views
            if isGridView {
                gridView
            } else {
                listView
            }
        }
        .sheet(isPresented: $isTileSizePromptPresented) {
            TileSizeInputView(tileSize: $tileSize, isPresented: $isTileSizePromptPresented, onTileSizeSelected: splitTilemap)
        }
    }

    // MARK: - List View
    private var listView: some View {
        List {
            ForEach(imageGroupItem.images.indices, id: \.self) { index in
                HStack {
                    // Display the image (adapt for platform)
                    #if os(iOS)
                    if let uiImage = UIImage(data: imageGroupItem.images[index]) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 100, maxHeight: 100)
                            .cornerRadius(8)

                        // Display index and dimensions
                        Text("Index: \(index) (\(Int(uiImage.size.width)) x \(Int(uiImage.size.height)))")
                            .foregroundColor(.gray)
                            .onTapGesture {
                                selectedImageIndex = index
                            }
                    }
                    #elseif os(macOS)
                    if let nsImage = NSImage(data: imageGroupItem.images[index]) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 100, maxHeight: 100)
                            .cornerRadius(8)

                        // Display index and dimensions
                        Text("Index: \(index) (\(Int(nsImage.size.width)) x \(Int(nsImage.size.height)))")
                            .foregroundColor(.gray)
                            .onTapGesture {
                                selectedImageIndex = index
                            }
                    }
                    #endif

                    Spacer()

                    // Select the image
                    Button(action: {
                        selectedImageIndex = index
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(selectedImageIndex == index ? .blue : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .onMove(perform: moveItem)
            .onDelete { indexSet in
                imageGroupItem.images.remove(atOffsets: indexSet)
            }
        }
        #if os(iOS)
        .environment(\.editMode, .constant(.active))
        #endif
    }

    // MARK: - Grid View
    private var gridView: some View {
        let columns = [
            GridItem(.adaptive(minimum: 48), spacing: 1)
        ]

        return ScrollView {
            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(imageGroupItem.images.indices, id: \.self) { index in
                    if let nsImage = NSImage(data: imageGroupItem.images[index]) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                            .onTapGesture {
                                selectedImageIndex = index
                            }
                            .overlay(
                                selectedImageIndex == index ?
                                Rectangle()
                                    .stroke(Color.accentColor, lineWidth: 2)
                                : nil
                            )
                    }
                }
            }
        }
    }

    // MARK: - Tilemap Dialog
    private func openTilemapDialog() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg]

        if panel.runModal() == .OK, let url = panel.urls.first, let imageData = try? Data(contentsOf: url) {
            selectedTilemapData = imageData
            isTileSizePromptPresented = true
        }
        #endif
    }

    private func splitTilemap(tileSize: CGFloat) {
        guard let tilemapData = selectedTilemapData else { return }
        guard let newImages = ImageGroupItem.createFromTilemap(tilemapData: tilemapData, tileSize: tileSize, name: "Tilemap")?.images else {
            print("Failed to split tilemap")
            return
        }

        imageGroupItem.images.append(contentsOf: newImages)
        selectedImageIndex = imageGroupItem.images.count - 1
    }

    // MARK: - Move Item
    private func moveItem(from source: IndexSet, to destination: Int) {
        imageGroupItem.images.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - macOS File Dialog
    #if os(macOS)
    private func openFileDialogMacOS() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg]

        if panel.runModal() == .OK {
            for url in panel.urls {
                if let imageData = try? Data(contentsOf: url) {
                    imageGroupItem.images.append(imageData)
                }
            }
            selectedImageIndex = imageGroupItem.images.count - 1
        }
    }
    #endif

    // MARK: - iOS File Dialog
    #if os(iOS)
    private func openFileDialogiOS() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.image], asCopy: true)
        documentPicker.delegate = DocumentPickerDelegate { url in
            if let url = url, let imageData = try? Data(contentsOf: url) {
                imageGroupItem.images.append(imageData)
                selectedImageIndex = imageGroupItem.images.count - 1
            }
        }
        if let controller = UIApplication.shared.windows.first?.rootViewController {
            controller.present(documentPicker, animated: true)
        }
    }

    class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
        private let completion: (URL?) -> Void

        init(completion: @escaping (URL?) -> Void) {
            self.completion = completion
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            completion(urls.first)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            completion(nil)
        }
    }
    #endif
}

struct TileSizeInputView: View {
    @Binding var tileSize: CGFloat
    @Binding var isPresented: Bool
    var onTileSizeSelected: (CGFloat) -> Void

    var body: some View {
        VStack {
            Text("Enter Tile Size")
                .font(.headline)

            TextField("Tile Size", value: $tileSize, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                Button("OK") {
                    onTileSizeSelected(tileSize)
                    isPresented = false
                }
                .disabled(tileSize <= 0)
            }
            .padding()
        }
        .frame(width: 300, height: 150)
    }
}
