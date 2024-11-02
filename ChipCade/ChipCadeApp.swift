//
//  ChipCadeApp.swift
//  ChipCade
//
//  Created by Markus Moenig on 28/9/24.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var showHelpReference = false
}

@main
struct ChipCadeApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        DocumentGroup(newDocument: ChipCadeDocument()) { file in
            ContentView(document: file.$document)
                .environmentObject(appState)
        }
        .commands {
            CommandGroup(replacing: .help) {
                Button("CHIPcade Help") {
//                    if let url = URL(string: "https://www.chipcade.com") {
//                        NSWorkspace.shared.open(url)
//                    }
                    appState.showHelpReference = true
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
        .defaultSize(width: 1200, height: 800)
    }
}
