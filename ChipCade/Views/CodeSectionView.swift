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

    @State private var isRenaming: Bool = false
    @State private var newName: String = ""

    @State private var selection                        : UUID? = nil

    @Environment(\.undoManager) var undoManager

    var body: some View {
        Section(header: Text(title).font(.headline)) {
            ForEach(codeItems.indices, id: \.self) { index in
                HStack {
                    if isRenaming && selectedCodeItem === codeItems[index] {
                        TextField("New Name", text: $newName, onCommit: {
                            codeItems[index].rename(to: newName, using: undoManager) { newItem in
                                selectedCodeItem = newItem
                            }
                            isRenaming = false
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        if selectedCodeItem === codeItems[index] {
                            Button(action: {
                                selectedCodeItem = codeItems[index]
                                Game.shared.scriptEditor?.setSession("mainSession")
                            }) {
                                HStack {
                                    Text(codeItems[index].name)
                                        .foregroundColor(.primary)
                                        .padding(.leading, 10)
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button(action: {
                                selectedCodeItem = codeItems[index]
                                Game.shared.scriptEditor?.setSession("mainSession")
                            }) {
                                HStack {
                                    Text(codeItems[index].name)
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


struct NewCodeItemPopup: View {
    @Binding var isPresented: Bool
    @State private var newName: String = ""
    let addItem: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("New Item").font(.headline)
            TextField("Enter name", text: $newName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                Spacer()
                Button("Add") {
                    if !newName.isEmpty {
                        addItem(newName)
                        isPresented = false
                    }
                }
                .disabled(newName.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(maxWidth: 400)
        .cornerRadius(12)
        .shadow(radius: 8)
    }
}
