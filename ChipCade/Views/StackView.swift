//
//  StackView.swift
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

import SwiftUI

// StackView to display the stack with offsets
struct StackView: View {
    @ObservedObject var game : Game
    
    var body: some View {
        VStack {
            Text("Stack")
                .font(.headline)
                .foregroundColor(.gray)

            List(Array(game.stack.enumerated()), id: \.offset) { index, data in
                HStack {

                    Text(String(format: "%04X", index))
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 60, alignment: .leading)
                    
                    // Display the name or value of the MemoryItem
                    Text(game.stack[index].toString())
                        .font(.system(.body, design: .monospaced))
                        .padding(.leading, 5)
                }
            }
            .frame(maxHeight: 150, alignment: .bottom)
        }
    }
}
