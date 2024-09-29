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
    
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 4) // 8 columns in the grid
    let bytesPerLine: Int = 4  // Number of memory values displayed per line
    let maxGridWidth: CGFloat = 300  // Maximum width for the grid view

    var body: some View {
        VStack {
            Text("Memory for: \(memoryItem.name)")
                .font(.headline)
                .padding(.bottom, 10)

            ScrollView {
                ForEach(0..<memoryItem.memory.count / bytesPerLine, id: \.self) { lineIndex in
                    HStack {
                        // Display the memory address at the start of the line
                        let lineStart = lineIndex * bytesPerLine
                        Text(String(format: "%04X", lineStart))
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 60, alignment: .leading)

                        // TextField for the hex values in the line
                        TextField(lineHexString(for: lineStart..<(lineStart + bytesPerLine)), text: Binding(
                            get: { lineHexString(for: lineStart..<(lineStart + bytesPerLine)) },
                            set: { newValue in
                                let validatedValue = validateHexInput(newValue, range: lineStart..<(lineStart + bytesPerLine))
                                updateBytes(for: lineStart..<(lineStart + bytesPerLine), with: validatedValue)
                            }
                        ))
                        .font(.system(.body, design: .monospaced))
                        .textFieldStyle(PlainTextFieldStyle())
                        .frame(minWidth: 100, alignment: .trailing)
                    }
                    .padding(.vertical, 2)
                }
            }
            .clipped()
        }
        .padding()
        .frame(maxWidth: maxGridWidth)  // Apply max width constraint to the entire ScrollView
    }

    // MARK: - Helper Functions

    // Converts a range of memory values to a hex string
    func lineHexString(for range: Range<Int>) -> String {
        return range.map { index in
            memoryItem.memory[index].toHexString()
        }.joined(separator: " ")
    }

    // Validates and cleans the hex input from the user
    func validateHexInput(_ input: String, range: Range<Int>) -> [String] {
        // Clean and ensure valid hex input per byte
        let hexBytes = input
            .split(separator: " ")
            .map { String($0.prefix(4)) }  // Limiting to 4 characters for 16-bit values
        return hexBytes.prefix(range.count).map { $0.uppercased() }
    }

    // Updates the memory values with new hex input
    func updateBytes(for range: Range<Int>, with hexValues: [String]) {
        for (index, hex) in hexValues.enumerated() {
            if let newValue = UInt16(hex, radix: 16) {
                memoryItem.memory[range.lowerBound + index] = .unsigned16Bit(newValue)
            }
        }
    }
}

extension ChipCadeData {
    // Convert ChipCadeData to a hex string
    func toHexString() -> String {
        switch self {
        case .unsigned16Bit(let value):
            return String(format: "%04X", value)
        case .signed16Bit(let value):
            return String(format: "%04X", UInt16(bitPattern: value))  // Treat as unsigned
        case .float16Bit(let value):
            return String(format: "%04X", value)
        }
    }
}

struct MemoryCellView: View {
    var memoryData: ChipCadeData
    
    var body: some View {
        Text(memoryData.description())
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .padding(8)
            .frame(width: 60, height: 40)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(5)
            .overlay(RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1))
    }
}

/*
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
*/
