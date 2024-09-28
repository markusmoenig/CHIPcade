//
//  MemoryGridView.swift
//  ChipCade
//
//  Created by Markus Moenig on 28/9/24.
//

import SwiftUI
import Combine

struct MemoryGridView: View {
    @ObservedObject var game: Game
    let range: Range<Int> // Memory range to display
    let columns: Int = 8

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(Array(stride(from: range.lowerBound, to: range.upperBound, by: columns)), id: \.self) { lineStart in
                    let lineRange = lineStart..<min(lineStart + columns, range.upperBound)
                    
                    HStack {
                        // Display the memory address at the start of the line
                        Text(String(format: "%04X", lineStart))
                            .font(.system(.body, design: .monospaced))
                            //.frame(width: 60, alignment: .leading) // Fixed width for addresses

                        // TextField for the hex values in the line
                        TextField(lineHexString(for: lineRange), text: Binding(
                            get: { lineHexString(for: lineRange) },
                            set: { newValue in
                                let validatedValue = validateHexInput(newValue)
                                updateBytes(for: lineRange, with: validatedValue)
                            }
                        ))
                        .font(.system(.body, design: .monospaced))
                        //.frame(height: 40)
                        //.background(Color.gray.opacity(0.1))
                        //.border(Color.gray)
                        //.keyboardType(.asciiCapable) // Restrict to ASCII characters for hex input

                    }
                }
            }
            .padding()
        }
    }

    // Converts a range of bytes into a single hex string for one line
    private func lineHexString(for range: Range<Int>) -> String {
        return range.map { String(format: "%02X", game.readByte(at: $0)) }
            .joined(separator: " ")
    }

    // Update the bytes in memory based on the edited hex string
    private func updateBytes(for range: Range<Int>, with newValue: String) {
        let byteStrings = newValue.split(separator: " ") // Split string by spaces
        for (index, byteString) in byteStrings.prefix(range.count).enumerated() {
            if let newByte = UInt8(byteString, radix: 16) {
                game.writeByte(at: range.lowerBound + index, value: newByte)
            }
        }
    }
    
    private func validateHexInput(_ input: String) -> String {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789ABCDEFabcdef ")
        let filtered = input.unicodeScalars.filter { allowedCharacters.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }
}
