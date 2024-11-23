//
//  AudioItem.swift
//  CHIPcade
//
//  Created by Markus Moenig on 22/11/24.
//

import Combine
import SwiftUI

// MARK: - MapItem
class MapItem: ObservableObject, Codable, Equatable, Identifiable {
    var id: UUID

    @Published var name: String

    var sectors: [Int: Sector] = [:]
    var vertices: [Int: Vertex] = [:]
    var linedefs: [Int: Linedef] = [:]

    private enum CodingKeys: String, CodingKey {
        case id, name, sectors, vertices, linedefs
    }

    init(name: String) {
        self.id = UUID()
        self.name = name
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        sectors = try container.decode([Int: Sector].self, forKey: .sectors)
        vertices = try container.decode([Int: Vertex].self, forKey: .vertices)
        linedefs = try container.decode([Int: Linedef].self, forKey: .linedefs)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(sectors, forKey: .sectors)
        try container.encode(vertices, forKey: .vertices)
        try container.encode(linedefs, forKey: .linedefs)
    }

    func rename(to newName: String, using undoManager: UndoManager?, setSelectedItem: @escaping (MapItem?) -> Void) {
        let previousName = self.name
        self.name = newName

        // Trigger a UI update by setting the selected item
        setSelectedItem(self)

        // Register undo action to restore the previous name
        undoManager?.registerUndo(withTarget: self) { targetSelf in
            targetSelf.name = previousName
            setSelectedItem(targetSelf)  // Set as selected again after undo

            // Register redo action to rename the item again
            undoManager?.registerUndo(withTarget: targetSelf) { redoSelf in
                redoSelf.rename(to: newName, using: undoManager, setSelectedItem: setSelectedItem)
            }
        }
        undoManager?.setActionName("Rename Map Item")
    }

    static func == (lhs: MapItem, rhs: MapItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Sector
class Sector: Codable, ObservableObject {
    let id: Int
    var vertices: [Int] = []
    var floorHeight: Float = 0
    var ceilingHeight: Float = 0
    var floorTexture: String = ""
    var ceilingTexture: String = ""
    var lightLevel: Float = 1.0
    var neighbors: [Int] = []

    init(id: Int) {
        self.id = id
    }
}

// MARK: - Vertex
struct Vertex: Codable, Hashable {
    let id: Int
    var x: Float
    var y: Float
}

// MARK: - Linedef
struct Linedef: Codable, Hashable {
    let id: Int
    let startVertex: Int
    let endVertex: Int
    var texture: String?
    var isPortal: Bool // If the line connects two sectors
    var frontSector: Int
    var backSector: Int? // Nil if this is a solid wall
}
