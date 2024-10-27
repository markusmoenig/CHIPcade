//
//  SpriteItemListView.swift
//  CHIPcade
//
//  Created by Markus Moenig on 7/10/24.
//

import SwiftUI

struct ImageGroupItemListView: View {
    @ObservedObject var imageGroupItem: ImageGroupItem
    @Binding var selectedImageIndex: Int?

    var body: some View {
        VStack {
            // Add Button
            HStack {
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
            }

            // List of Images with Drag-and-Drop Reordering
            List {
                ForEach(imageGroupItem.images.indices, id: \.self) { index in
                    HStack {
                        // Display the image (assumes image data, update logic as needed)
                        #if os(iOS)
                        if let uiImage = UIImage(data: imageGroupItem.images[index]) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit) // Maintain aspect ratio
                                .frame(maxWidth: 100, maxHeight: 100) // Set max size for the thumbnail
                                .cornerRadius(8)
                        }
                        #elseif os(macOS)
                        if let nsImage = NSImage(data: imageGroupItem.images[index]) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit) // Maintain aspect ratio
                                .frame(maxWidth: 100, maxHeight: 100) // Set max size for the thumbnail
                                .cornerRadius(8)
                        }
                        #endif
                        
                        // Show the index of the image
                        Text("Index: \(index)")
                            //.font(.caption)
                            .foregroundColor(.gray)
                            .onTapGesture {
                                selectedImageIndex = index
                            }
                        
                        Spacer()

                        // Select the image by setting the index
                        Button(action: {
                            selectedImageIndex = index // Select the current image index
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(selectedImageIndex == index ? .blue : .gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .onMove(perform: moveItem) // Enable drag-and-drop reordering
                .onDelete { indexSet in
                    imageGroupItem.images.remove(atOffsets: indexSet)
                }
            }

            #if os(iOS)
            .environment(\.editMode, .constant(.active)) // Enable editing mode for dragging only on iOS
            #endif
        }
    }

    // Move item for drag-and-drop reordering
    private func moveItem(from source: IndexSet, to destination: Int) {
        imageGroupItem.images.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - macOS File Dialog
    #if os(macOS)
    private func openFileDialogMacOS() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg]
        if panel.runModal() == .OK, let url = panel.url {
            if let imageData = try? Data(contentsOf: url) {
                imageGroupItem.images.append(imageData)
                selectedImageIndex = imageGroupItem.images.count - 1
            }
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
                selectedImageIndex = imageGroupItem.images.count - 1 // Set to new image index
            }
        }
        if let controller = UIApplication.shared.windows.first?.rootViewController {
            controller.present(documentPicker, animated: true)
        }
    }

    // Custom Document Picker Delegate for iOS
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
