//
//  CodeView.swift
//  CHIPcade
//
//  Created by Markus Moenig on 29/10/24.
//

import SwiftUI
import CodeEditorView
import LanguageSupport

struct CodeView: View {
    @Binding var codeItem: CodeItem?
    
    @State private var codeText: String = "My awesome code..."
    @State private var position: CodeEditor.Position = CodeEditor.Position()
    @State private var messages: Set<TextLocated<Message>> = Set()
    
    var body: some View {
        VStack {
            if let codeItem = codeItem {
                //CodeEditor(text: $codeText, position: $position, messages: $messages, language: .swift())
//                TextEditor(text: .constant(formatCode(codeItem)))
//                    .font(.system(.body, design: .monospaced))
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
