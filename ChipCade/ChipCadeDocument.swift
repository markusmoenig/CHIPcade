//
//  ChipCadeDocument.swift
//  ChipCade
//
//  Created by Markus Moenig on 28/9/24.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var ChipCadeDocument: UTType {
        UTType(exportedAs: "com.chipcade.document")
    }
}

struct ChipCadeDocument: FileDocument {
    
    var game : Game
    
    init() {
        game = Game.shared
        game.data = .init()
    }

    static var readableContentTypes: [UTType] { [.ChipCadeDocument] }
    static var writableContentTypes: [UTType] { [.ChipCadeDocument] }

    init(configuration: ReadConfiguration) throws {
        game = Game.shared
        game.reset()
        
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadNoSuchFile) // Changed to reflect the issue better
        }
        
        do {
            let gameData = try JSONDecoder().decode(GameData.self, from: data)
            self.game.data = gameData
        } catch {
            print("Error: Failed to decode Game object. Details: \(error)")
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        var data = Data()
        
        let encodedData = try? JSONEncoder().encode(game.data)
        if let json = String(data: encodedData!, encoding: .utf8) {
            data = json.data(using: .utf8)!
        }
        
        return .init(regularFileWithContents: data)
    }
}
