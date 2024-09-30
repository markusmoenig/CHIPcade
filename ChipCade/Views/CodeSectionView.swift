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
                        Button(action: {
                            selectedCodeItem = codeItems[index]
                            selectedMemoryItem = nil
                            print("\(index)")
                        }) {
                            HStack {
                                Text(codeItems[index].name)
                                    .foregroundColor(.primary)
                                    .padding(.leading, 10) // Add padding to the left side
                                Spacer()
                            }
                            .padding(.vertical, 6) // Vertical padding to increase height
                            .background(
                                RoundedRectangle(cornerRadius: 8) // Rounded background
                                    .fill(selectedCodeItem === codeItems[index] ? Color.accentColor.opacity(0.2) : Color.clear)
                            )
                        }
                        .buttonStyle(PlainButtonStyle()) // No button decoration
                    }

                    Spacer()

                    #if !os(macOS)
                    // Only show rename and delete buttons on iOS
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
                    #endif
                }
                .contextMenu {
                    // Context menu for renaming and deleting
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
