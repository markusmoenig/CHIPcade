//
//  AudioSectionView.swift
//  CHIPcade
//
//  Created by Markus Moenig on 22/11/24.
//

import SwiftUI

struct MapSectionView: View {
    let title: String
    
    @Binding var gameData: GameData
    @Binding var mapItems: [MapItem]
    @Binding var selectedMapItem: MapItem?
    
    @State private var isRenaming: Bool = false
    @State private var newName: String = ""

    @Environment(\.undoManager) var undoManager

    var body: some View {
        Section(header: Text(title).font(.headline)) {
            ForEach(mapItems.indices, id: \.self) { index in
                HStack {
                    if isRenaming && selectedMapItem === mapItems[index] {
                        TextField("New Name", text: $newName, onCommit: {
                            mapItems[index].rename(to: newName, using: undoManager)  { newItem in
                                selectedMapItem = newItem
                            }
                            isRenaming = false
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                    } else {
                        if selectedMapItem === mapItems[index] {
                            Button(action: {
                                selectedMapItem = mapItems[index]
                            }) {
                                HStack {
                                    Text(mapItems[index].name)
                                        .foregroundColor(.primary)
                                        .padding(.leading, 10)
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button(action: {
                                selectedMapItem = mapItems[index]
                            }) {
                                HStack {
                                    Text(mapItems[index].name)
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
                        startRenaming(item: mapItems[index])
                    }) {
                        Text("Rename")
                        Image(systemName: "pencil")
                    }

                    Button(action: {
                        gameData.deleteMapItem(at: index, using: undoManager){ newItem in
                            selectedMapItem = newItem
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

    private func startRenaming(item: MapItem) {
        newName = item.name
        selectedMapItem = item
        isRenaming = true
    }

    private func deleteItem(at index: Int) {
        mapItems.remove(at: index)
        selectedMapItem = nil
    }
}
