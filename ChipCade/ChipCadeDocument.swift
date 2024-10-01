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
    var game = Game()

    init() {
    }

    static var readableContentTypes: [UTType] { [.ChipCadeDocument] }
    static var writableContentTypes: [UTType] { [.ChipCadeDocument] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadNoSuchFile) // Changed to reflect the issue better
        }
        
        do {
            let g = try JSONDecoder().decode(Game.self, from: data)
            game = g
        } catch {
            print("Error: Failed to decode Game object. Details: \(error)")
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        var data = Data()
        
        let encodedData = try? JSONEncoder().encode(game)
        if let json = String(data: encodedData!, encoding: .utf8) {
            data = json.data(using: .utf8)!
        }
        
        return .init(regularFileWithContents: data)
    }
}
