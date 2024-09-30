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
    var draw2D = MetalDraw2D()

    init() {
    }

    static var readableContentTypes: [UTType] { [.ChipCadeDocument] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let g = try? JSONDecoder().decode(Game.self, from: data)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        game = g
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
