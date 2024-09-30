//
//  MemorySectionView.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct MemorySectionView: View {
    let title: String
    @Binding var memoryItems: [MemoryItem]
    @Binding var selectedMemoryItem: MemoryItem?
    @Binding var selectedCodeItem: CodeItem?

    @State private var isRenaming: Bool = false
    @State private var newName: String = ""

    var body: some View {
        Section(header: Text(title).font(.headline)) {
            ForEach(memoryItems.indices, id: \.self) { index in
                HStack {
                    if isRenaming && selectedMemoryItem === memoryItems[index] {
                        TextField("New Name", text: $newName, onCommit: {
                            memoryItems[index].name = newName
                            isRenaming = false
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                    } else {
                        Text(memoryItems[index].name)
                            .onTapGesture {
                                selectedMemoryItem = memoryItems[index]
                                selectedCodeItem = nil
                            }
                            .padding(.vertical, 4)
                            .background(selectedMemoryItem === memoryItems[index] ? Color.blue.opacity(0.2) : Color.clear)
                    }

                    Spacer()

                    // Rename and delete buttons for both platforms
                    Button(action: {
                        startRenaming(item: memoryItems[index])
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
                        startRenaming(item: memoryItems[index])
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

struct MemoryItemView: View {
    @Binding var memoryItem: MemoryItem
    @State private var isEditingName = false
    
    var body: some View {
        HStack {
            if isEditingName {
                TextField("Name", text: $memoryItem.name, onCommit: {
                    isEditingName = false
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                Text(memoryItem.name)
                    .onTapGesture {
                        isEditingName = true
                    }
            }
            //Spacer()
//            Text("Start: \(memoryItem.startAddress)")
            Text("Length: \(memoryItem.memory.count)")
        }
    }
}
