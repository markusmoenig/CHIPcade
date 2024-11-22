//
//  AudioSectionView.swift
//  CHIPcade
//
//  Created by Markus Moenig on 22/11/24.
//

import SwiftUI

struct AudioSectionView: View {
    let title: String
    
    @Binding var gameData: GameData
    @Binding var audioItems: [AudioItem]
    @Binding var selectedAudioItem: AudioItem?
    
    @State private var isRenaming: Bool = false
    @State private var newName: String = ""

    @Environment(\.undoManager) var undoManager

    var body: some View {
        Section(header: Text(title).font(.headline)) {
            ForEach(audioItems.indices, id: \.self) { index in
                HStack {
                    if isRenaming && selectedAudioItem === audioItems[index] {
                        TextField("New Name", text: $newName, onCommit: {
                            audioItems[index].rename(to: newName, using: undoManager)  { newItem in
                                selectedAudioItem = newItem
                            }
                            isRenaming = false
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                    } else {
                        if selectedAudioItem === audioItems[index] {
                            Button(action: {
                                selectedAudioItem = audioItems[index]
                            }) {
                                HStack {
                                    Text(audioItems[index].name)
                                        .foregroundColor(.primary)
                                        .padding(.leading, 10)
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button(action: {
                                selectedAudioItem = audioItems[index]
                            }) {
                                HStack {
                                    Text(audioItems[index].name)
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
                        startRenaming(item: audioItems[index])
                    }) {
                        Text("Rename")
                        Image(systemName: "pencil")
                    }

                    Button(action: {
                        gameData.deleteAudioItem(at: index, using: undoManager){ newItem in
                            selectedAudioItem = newItem
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

    private func startRenaming(item: AudioItem) {
        newName = item.name
        selectedAudioItem = item
        isRenaming = true
    }

    private func deleteItem(at index: Int) {
        audioItems.remove(at: index)
        selectedAudioItem = nil
    }
}
