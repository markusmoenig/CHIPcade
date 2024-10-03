//
//  PaletteView.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct PaletteView: View {
    @ObservedObject var game: Game
    @State private var selectedColorIndex: Int? = nil
    @State private var showingColorPicker = false

    let colorBlockSize: CGFloat = 20
    let spacing: CGFloat = 2
    let padding: CGFloat = 10

    var body: some View {
        VStack {
            // A scrollable grid layout for the colors that adjusts to the available width
            ScrollView {
                GeometryReader { geometry in
                    let availableWidth = geometry.size.width - padding * 2
                    let totalItemWidth = colorBlockSize + spacing
                    let numberOfColumns = max(Int(availableWidth / totalItemWidth), 1) // Ensure at least 1 column

                    let columns = Array(repeating: GridItem(.fixed(colorBlockSize), spacing: spacing), count: numberOfColumns)

                    LazyVGrid(columns: columns, spacing: spacing) {
                        ForEach(0..<game.data.palette.count, id: \.self) { index in
                            game.data.color(at: index)
                                .frame(width: colorBlockSize, height: colorBlockSize)
                                .border(selectedColorIndex == index ? Color.primary : Color.black, width: selectedColorIndex == index ? 2 : 1)
                                .onTapGesture {
                                    if selectedColorIndex == index {
                                        showingColorPicker = true // Keep picker open for the same color
                                    } else {
                                        selectedColorIndex = index
                                        showingColorPicker = true // Show picker for new selection
                                    }
                                }
                        }
                    }
                    .padding(padding)
                }
            }

            // Display the selected color index if a color is selected
            if let selectedIndex = selectedColorIndex {
                Text("Color Index: \(selectedIndex)")
                    .padding()
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Show the color picker when a color is selected
            if let selectedIndex = selectedColorIndex, showingColorPicker {
                ColorPicker("Select Color", selection: Binding(
                    get: {
                        game.data.color(at: selectedIndex)
                    },
                    set: { newColor in
                        game.data.updateColor(at: selectedIndex, to: newColor)
                    }
                ))
                .frame(width: 200)
                .padding()
            }
        }
    }
}
