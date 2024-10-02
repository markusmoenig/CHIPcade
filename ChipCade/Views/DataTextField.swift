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
                } else {
                    // Revert if the input is invalid
                    textValue = chipCadeData.toString()
                }
            }
    }

    // Parse the ChipCadeData from the text input, auto-detect negative and float values
    func parseChipCadeData(from text: String) -> ChipCadeData? {
        if text.contains(".") {
            if let value = Float(text) {
                let float16 = chipCadeData.float32ToFloat16(value)
                return .float16Bit(float16)
            }
        } else if text.hasPrefix("-") {
            if let value = Int16(text) {
                return .signed16Bit(value)
            }
        } else if text.hasSuffix("u") {
            if let value = UInt16(text.dropLast()) {
                return .unsigned16Bit(value)
            }
        } else if text.hasSuffix("s") {
            if let value = Int16(text.dropLast()) {
                return .signed16Bit(value)
            }
        } else if text.hasSuffix("f") {
            if let value = Float(text.dropLast()) {
                let float16 = chipCadeData.float32ToFloat16(value)
                return .float16Bit(float16)
            }
        } else {
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
                    let float16 = chipCadeData.float32ToFloat16(value)
                    return .float16Bit(float16)
                }
            }
        }
        return nil
    }
}
