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
    }
}
