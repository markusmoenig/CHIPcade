//
//  ChipCadeApp.swift
//  ChipCade
//
//  Created by Markus Moenig on 28/9/24.
//

import SwiftUI

@main
struct ChipCadeApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: ChipCadeDocument()) { file in
            ContentView(document: file.$document)
        }
        .commands {
            CommandGroup(replacing: .pasteboard) {
                Button("Cut") {
                    /*
                    handleClipboard { view in
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        if let cutText = view.cutText() {
                            pasteboard.setString(cutText, forType: .string)
                        }
                    }*/
                }
                .keyboardShortcut("x", modifiers: .command)

                Button("Copy") {
                    /*
                    handleClipboard { view in
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        if let copiedText = view.copyText() {
                            pasteboard.setString(copiedText, forType: .string)
                        }
                    }*/
                    #if os(macOS)
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    if let instruction = Game.shared.getInstruction() {
                        let text = instruction.format()
                        pasteboard.setString(text, forType: .string)
                    }
                    #endif
                }
                .keyboardShortcut("c", modifiers: .command)

                Button("Paste") {
                    /*
                    handleClipboard { view in
                        if let pasteText = NSPasteboard.general.string(forType: .string) {
                            view.pasteText(pasteText)
                        }
                    }*/
                }
                .keyboardShortcut("v", modifiers: .command)
            }
        }
        .defaultSize(width: 1200, height: 800)
    }
}
