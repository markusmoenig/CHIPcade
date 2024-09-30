//
//  DataTextField.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

struct ChipCadeDataTextField: View {
    @Binding var chipCadeData: ChipCadeData
    @State private var textValue: String = ""
    
    // Store the original ChipCadeData type for fallback
    var originalType: ChipCadeData
    
    init(chipCadeData: Binding<ChipCadeData>) {
        _chipCadeData = chipCadeData
        _textValue = State(initialValue: chipCadeData.wrappedValue.toString())
        self.originalType = chipCadeData.wrappedValue
    }

    var body: some View {
        TextField("", text: $textValue, onCommit: {
            if let newValue = parseChipCadeData(from: textValue) {
                chipCadeData = newValue
                DispatchQueue.main.async {
                    textValue = newValue.toString()
                }
            } else {
                // Revert to the original value if input is invalid
                DispatchQueue.main.async {
                    textValue = chipCadeData.toString()
                }
            }
        })
        .textFieldStyle(RoundedBorderTextFieldStyle())
        //.frame(width: 80)
    }

    // Parse the ChipCadeData from the text input, auto-detect negative and float values
    func parseChipCadeData(from text: String) -> ChipCadeData? {
        // Automatically detect float if it contains "."
        if text.contains(".") {
            if let value = Float(text) {
                let float16 = chipCadeData.float32ToFloat16(value)
                return .float16Bit(float16)
            }
        }
        
        // Automatically treat values with a leading "-" as signed
        if text.hasPrefix("-") {
            if let value = Int16(text) {
                return .signed16Bit(value)
            }
        }
        
        // Check for U, S, F suffixes
        if text.hasSuffix("U") {
            if let value = UInt16(text.dropLast()) {
                return .unsigned16Bit(value)
            }
        } else if text.hasSuffix("S") {
            if let value = Int16(text.dropLast()) {
                return .signed16Bit(value)
            }
        } else if text.hasSuffix("F") {
            if let value = Float(text.dropLast()) {
                let float16 = chipCadeData.float32ToFloat16(value)
                return .float16Bit(float16)
            }
        } else {
            // If no suffix, use the original type to interpret the value
            switch originalType {
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
        
        // If the input is invalid, return nil
        return nil
    }
}
