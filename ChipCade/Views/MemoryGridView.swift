//
//  MemoryGridView.swift
//  ChipCade
//
//  Created by Markus Moenig on 28/9/24.
//

import SwiftUI
import Combine

struct MemoryGridView: View {
    @ObservedObject var memoryItem: MemoryItem
    @Environment(\.undoManager) var undoManager  // Get the undo manager from the environment

    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 4) // 4 columns in the grid
    let bytesPerLine: Int = 4  // Number of memory values displayed per line

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack {
                    ForEach(0..<memoryItem.memory.count / bytesPerLine, id: \.self) { lineIndex in
                        HStack {
                            let lineStart = lineIndex * bytesPerLine
                            Text(String(format: "%03X", lineStart))
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 40, alignment: .leading)

                            ForEach(0..<bytesPerLine, id: \.self) { byteIndex in
                                let memoryIndex = lineStart + byteIndex
                                ChipCadeDataTextField(chipCadeData: Binding(
                                    get: { memoryItem.memory[memoryIndex] },
                                    set: { newValue in
                                        memoryItem.aboutToChange(using: undoManager, newValue: newValue, at: memoryIndex)

                                    }
                                ))
                                .frame(minWidth: 60, alignment: .trailing)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .clipped()
        }
        .padding()
    }
}
