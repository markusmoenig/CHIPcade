//
//  DataTextField.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct ChipCadeDataTextField: View {
    @Binding var chipCadeData: ChipCadeData
    @State private var textValue: String
    
    init(chipCadeData: Binding<ChipCadeData>) {
        _chipCadeData = chipCadeData
        _textValue = State(initialValue: chipCadeData.wrappedValue.toString())
    }

    var body: some View {
        TextField("", text: $textValue)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onSubmit {
                if let newChipCadeData = parseChipCadeData(from: textValue) {
                    chipCadeData = newChipCadeData
                    textValue = chipCadeData.toString()
                    Game.shared.cpuRender.update()
                } else {
                    // Revert if the input is invalid
                    textValue = chipCadeData.toString()
                }
            }
    }

    // Parse the ChipCadeData from the text input, auto-detect negative, float, and Unicode values
    func parseChipCadeData(from text: String) -> ChipCadeData? {
        
        if let data = ChipCadeData.fromString(text: text, unsignedDefault: false) {
            return data
        }
            /*
        // Handle single-character input in quotes or backticks
        if (text.first == "\"" && text.last == "\"") || (text.first == "`" && text.last == "`") {
            let character = text.dropFirst().dropLast()
            if character.count == 1, let unicodeValue = character.unicodeScalars.first?.value, unicodeValue <= UInt16.max {
                return .unicodeChar(UInt16(unicodeValue))
            }
        }

        // Handle float values
        if text.contains(".") {
            if let value = Float(text) {
                let float16 = chipCadeData.float32ToFloat16(value)
                return .float16Bit(float16)
            }
        }

        // Handle signed 16-bit integers
        if text.hasPrefix("-") {
            if let value = Int16(text) {
                return .signed16Bit(value)
            }
        }

        // Handle unsigned 16-bit integers with suffixes
        if text.hasSuffix("u") {
            if let value = UInt16(text.dropLast()) {
                return .unsigned16Bit(value)
            }
        }

        // Handle signed 16-bit integers with suffixes
        if text.hasSuffix("s") {
            if let value = Int16(text.dropLast()) {
                return .signed16Bit(value)
            }
        }

        // Handle 16-bit float values with suffixes
        if text.hasSuffix("f") {
            if let value = Float(text.dropLast()) {
                let float16 = chipCadeData.float32ToFloat16(value)
                return .float16Bit(float16)
            }
        }*/

        // Default handling based on current data type
        switch chipCadeData {
        case .unsigned16Bit:
            if let value = UInt16(text) {
                return .unsigned16Bit(value)
            }
        case .signed16Bit:
            if let value = Int16(text) {
                return .signed16Bit(value)
            }
        case .float16Bit:
            if let value = Float(text) {
                let float16 = ChipCadeData.float32ToFloat16(value)
                return .float16Bit(float16)
            }
        case .unicodeChar:
            if let value = UInt16(text) {
                return .unicodeChar(value)
            }
        default:
            break;
        }

        // If no valid conversion, return nil
        return nil
    }
}
