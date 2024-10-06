//
//  MemorySectionView.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct MemorySectionView: View {
    let title: String
    
    @Binding var gameData: GameData
    @Binding var memoryItems: [MemoryItem]
    @Binding var selectedMemoryItem: MemoryItem?
    @Binding var selectedCodeItem: CodeItem?

    @State private var isRenaming: Bool = false
    @State private var newName: String = ""

    @Environment(\.undoManager) var undoManager

    var body: some View {
        Section(header: Text(title).font(.headline)) {
            ForEach(memoryItems.indices, id: \.self) { index in
                HStack {
                    if isRenaming && selectedMemoryItem === memoryItems[index] {
                        TextField("New Name", text: $newName, onCommit: {
                            memoryItems[index].rename(to: newName, using: undoManager)  { newItem in
                                selectedMemoryItem = newItem
                            }
                            isRenaming = false
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                    } else {
                        Button(action: {
                            selectedMemoryItem = memoryItems[index]
                            selectedCodeItem = nil
                        }) {
                            HStack {
                                Text(memoryItems[index].name)
                                    .foregroundColor(.primary)
                                    .padding(.leading, 10) // Add padding to the left side
                                Spacer()
                            }
                            .padding(.vertical, 6) // Add vertical padding
                            .background(
                                RoundedRectangle(cornerRadius: 8) // Rounded background
                                    .fill(selectedMemoryItem === memoryItems[index] ? Color.accentColor.opacity(0.2) : Color.clear)
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
                        startRenaming(item: memoryItems[index])
                    }) {
                        Text("Rename")
                        Image(systemName: "pencil")
                    }

                    Button(action: {
                        gameData.deleteDataItem(at: index, using: undoManager){ newItem in
                            selectedMemoryItem = newItem
                            selectedCodeItem = nil
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
