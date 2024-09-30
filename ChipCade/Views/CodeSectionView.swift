//
//  CodeSectionView.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct CodeSectionView: View {
    let title: String

    @Binding var codeItems: [CodeItem]
    @Binding var selectedCodeItem: CodeItem?
    @Binding var selectedMemoryItem: MemoryItem?

    @State private var isRenaming: Bool = false
    @State private var newName: String = ""

    var body: some View {
        Section(header: Text(title).font(.headline)) {
            ForEach(codeItems.indices, id: \.self) { index in
                HStack {
                    if isRenaming && selectedCodeItem === codeItems[index] {
                        TextField("New Name", text: $newName, onCommit: {
                            codeItems[index].name = newName
                            isRenaming = false
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                    } else {
                        Text(codeItems[index].name)
                            .onTapGesture {
                                selectedCodeItem = codeItems[index]
                                selectedMemoryItem = nil
                            }
                            .padding(.vertical, 4)
                            .background(selectedCodeItem === codeItems[index] ? Color.blue.opacity(0.2) : Color.clear)
                    }

                    Spacer()

                    // Rename and delete buttons for both platforms
                    Button(action: {
                        startRenaming(item: codeItems[index])
                    }) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.trailing, 8)

                    Button(action: {
                        deleteItem(at: index)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .contextMenu {
                    // macOS context menu for renaming and deleting
                    #if os(macOS)
                    Button(action: {
                        startRenaming(item: codeItems[index])
                    }) {
                        Text("Rename")
                        Image(systemName: "pencil")
                    }

                    Button(action: {
                        deleteItem(at: index)
                    }) {
                        Text("Delete")
                        Image(systemName: "trash")
                    }
                    .foregroundColor(.red)
                    #endif
                }
                #if os(iOS)
                .swipeActions {
                    // iOS swipe actions for deleting and renaming
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
