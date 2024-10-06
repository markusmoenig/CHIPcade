//
//  CodeSectionView.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct CodeSectionView: View {
    let title: String

    @Binding var gameData: GameData
    @Binding var codeItems: [CodeItem]
    @Binding var selectedCodeItem: CodeItem?
    @Binding var selectedMemoryItem: MemoryItem?

    @State private var isRenaming: Bool = false
    @State private var newName: String = ""

    @Environment(\.undoManager) var undoManager

    var body: some View {
        Section(header: Text(title).font(.headline)) {
            ForEach(codeItems.indices, id: \.self) { index in
                HStack {
                    if isRenaming && selectedCodeItem === codeItems[index] {
                        TextField("New Name", text: $newName, onCommit: {
                            //codeItems[index].name = newName
                            codeItems[index].rename(to: newName, using: undoManager) { newItem in
                                selectedCodeItem = newItem
                            }
                            isRenaming = false
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                    } else {
                        Button(action: {
                            selectedCodeItem = codeItems[index]
                            selectedMemoryItem = nil
                        }) {
                            HStack {
                                Text(codeItems[index].name)
                                    .foregroundColor(.primary)
                                    .padding(.leading, 10) // Add padding to the left side
                                Spacer()
                            }
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedCodeItem === codeItems[index] ? Color.accentColor.opacity(0.2) : Color.clear)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
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
                        startRenaming(item: codeItems[index])
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                #endif
                .contextMenu {
                    // Context menu for renaming and deleting
                    Button(action: {
                        startRenaming(item: codeItems[index])
                    }) {
                        Text("Rename")
                        Image(systemName: "pencil")
                    }

                    Button(action: {
                        gameData.deleteCodeItem(at: index, using: undoManager) { newItem in
                           selectedCodeItem = newItem
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
