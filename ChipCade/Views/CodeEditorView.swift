//
//  CodeEditorView.swift
//  CHIPcade
//
//  Created by Markus Moenig on 29/10/24.
//

import SwiftUI

struct CodeEditorView: View {
    @Binding var codeItem: CodeItem?

    var body: some View {
        VStack {
            if let codeItem = codeItem {
                TextEditor(text: .constant(formatCode(codeItem)))
                    .font(.system(.body, design: .monospaced))
//                    .padding()
//                    .border(Color.gray, width: 1)
            } else {
                Text("No Code Item Selected")
                    .foregroundColor(.gray)
                    .italic()
                    .padding()
            }
        }
    }

    private func formatCode(_ codeItem: CodeItem) -> String {
        // Convert the instructions in the code item to a formatted string
        return codeItem.codes.map { $0.format() }.joined(separator: "\n")
    }
}
