//
//  MemorySectionView.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct ImageGroupSectionView: View {
    let title: String
    
    @Binding var gameData: GameData
    @Binding var imageGroupItems: [ImageGroupItem]
    @Binding var selectedImageGroupItem: ImageGroupItem?
    @Binding var selectedMemoryItem: MemoryItem?
    @Binding var selectedCodeItem: CodeItem?

    @State private var isRenaming: Bool = false
    @State private var newName: String = ""

    @Environment(\.undoManager) var undoManager

    var body: some View {
        Section(header: Text(title).font(.headline)) {
            ForEach(imageGroupItems.indices, id: \.self) { index in
                HStack {
                    if isRenaming && selectedImageGroupItem === imageGroupItems[index] {
                        TextField("New Name", text: $newName, onCommit: {
                            imageGroupItems[index].rename(to: newName, using: undoManager)  { newItem in
                                selectedImageGroupItem = newItem
                            }
                            isRenaming = false
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                    } else {
                        
                        if selectedImageGroupItem === imageGroupItems[index] {
                            
                            Button(action: {
                                selectedImageGroupItem = imageGroupItems[index]
                                selectedCodeItem = nil
                                selectedMemoryItem = nil
                            }) {
                                HStack {
                                    Text(imageGroupItems[index].name)
                                        .foregroundColor(.primary)
                                        .padding(.leading, 10)
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button(action: {
                                selectedImageGroupItem = imageGroupItems[index]
                                selectedCodeItem = nil
                                selectedMemoryItem = nil
                            }) {
                                HStack {
                                    Text(imageGroupItems[index].name)
                                        .foregroundColor(.primary)
                                        .padding(.leading, 10)
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    Spacer()
                }
                #if os(iOS)
                .swipeActions {
                    Button(role: .destructive) {
                        deleteItem(at: index)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        startRenaming(item: imageGroupItems[index])
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                #endif
                .contextMenu {
                    // macOS context menu for renaming and deleting
                    Button(action: {
                        startRenaming(item: imageGroupItems[index])
                    }) {
                        Text("Rename")
                        Image(systemName: "pencil")
                    }

                    Button(action: {
                        gameData.deleteImageGroupItem(at: index, using: undoManager) { newItem in
                            selectedImageGroupItem = newItem
                            selectedCodeItem = nil
                            selectedMemoryItem = nil
                        }
                    }) {
                        Text("Delete")
                        Image(systemName: "trash")
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }

    private func startRenaming(item: ImageGroupItem) {
        newName = item.name
        selectedImageGroupItem = item
        isRenaming = true
    }

    private func deleteItem(at index: Int) {
        imageGroupItems.remove(at: index)
        selectedImageGroupItem = nil
    }
}
