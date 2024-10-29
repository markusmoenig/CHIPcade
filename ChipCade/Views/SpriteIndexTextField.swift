//
//  SpriteIndexTextField.swift
//  CHIPcade
//
//  Created by Markus Moenig on 7/10/24.
//

import SwiftUI

struct SpriteIndexTextField: View {
    @Binding var spriteIndex: Int
    @State private var textValue: String

    init(spriteIndex: Binding<Int>) {
        _spriteIndex = spriteIndex
        _textValue = State(initialValue: String(spriteIndex.wrappedValue))
    }

    var body: some View {
        TextField("Sprite Index", text: $textValue)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onSubmit {
                if let newSpriteIndex = parseSpriteIndex(from: textValue) {
                    spriteIndex = newSpriteIndex
                    textValue = String(newSpriteIndex)  // Update the text with the new valid value
                } else {
                    // Revert to the previous valid sprite index if the input is invalid
                    textValue = String(spriteIndex)
                }
            }
            .frame(maxWidth: 55)
    }

    // Parse the sprite index from the text input, ensuring it's between 0 and 128
    func parseSpriteIndex(from text: String) -> Int? {
        if let value = Int(text), value >= 0, value < 256 {
            return value
        }
        return nil  // Return nil if the value is out of range or invalid
    }
}
