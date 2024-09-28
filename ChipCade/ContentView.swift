//
//  ContentView.swift
//  ChipCade
//
//  Created by Markus Moenig on 28/9/24.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: ChipCadeDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(ChipCadeDocument()))
}
