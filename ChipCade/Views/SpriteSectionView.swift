//
//  MemorySectionView.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct SpriteSectionView: View {
    let title: String
    
    @Binding var gameData: GameData
    @Binding var spriteItems: [SpriteItem]
    @Binding var selectedSpriteItem: SpriteItem?
    @Binding var selectedMemoryItem: MemoryItem?
    @Binding var selectedCodeItem: CodeItem?

    @State private var isRenaming: Bool = false
    @State private var newName: String = ""

    @Environment(\.undoManager) var undoManager

    var body: some View {
        Section(header: Text(title).font(.headline)) {
            ForEach(spriteItems.indices, id: \.self) { index in
                HStack {
                    if isRenaming && selectedSpriteItem === spriteItems[index] {
                        TextField("New Name", text: $newName, onCommit: {
                            spriteItems[index].rename(to: newName, using: undoManager)  { newItem in
                                selectedSpriteItem = newItem
                            }
                            isRenaming = false
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                    } else {
                        Button(action: {
                            selectedSpriteItem = spriteItems[index]
                            selectedCodeItem = nil
                            selectedMemoryItem = nil
                        }) {
                            HStack {
                                Text(spriteItems[index].name)
                                    .foregroundColor(.primary)
                                    .padding(.leading, 10) // Add padding to the left side
                                Spacer()
                            }
                            .padding(.vertical, 6) // Add vertical padding
                            .background(
                                RoundedRectangle(cornerRadius: 8) // Rounded background
                                    .fill(selectedSpriteItem === spriteItems[index] ? Color.accentColor.opacity(0.2) : Color.clear)
                            )
                        }
                        .buttonStyle(PlainButtonStyle()) // No button decoration
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
                        startRenaming(item: memoryItems[index])
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                #endif
                .contextMenu {
                    // macOS context menu for renaming and deleting
                    Button(action: {
                        startRenaming(item: spriteItems[index])
                    }) {
                        Text("Rename")
                        Image(systemName: "pencil")
                    }

                    Button(action: {
                        gameData.deleteSpriteItem(at: index, using: undoManager) { newItem in
                            selectedSpriteItem = newItem
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

    private func startRenaming(item: SpriteItem) {
        newName = item.name
        selectedSpriteItem = item
        isRenaming = true
    }

    private func deleteItem(at index: Int) {
        spriteItems.remove(at: index)
        selectedSpriteItem = nil
    }
}
