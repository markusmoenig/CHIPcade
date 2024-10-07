//
//  SpriteItem.swift
//  CHIPcade
//
//  Created by Markus Moenig on 7/10/24.
//

import Combine
import SwiftUI

class SpriteItem : ObservableObject, Codable, Equatable, Identifiable {
    var id: UUID

    @Published var images: [Data]

    @Published var name: String

    private enum CodingKeys: String, CodingKey {
        case id, images, name
    }
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.images = []
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        images = try container.decode([Data].self, forKey: .images)
        name = try container.decode(String.self, forKey: .name)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(images, forKey: .images)
        try container.encode(name, forKey: .name)
    }
    
    func rename(to newName: String, using undoManager: UndoManager?, setSelectedItem: @escaping (SpriteItem?) -> Void) {
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
        undoManager?.setActionName("Rename Sprite Item")
    }
    
    static func == (lhs: SpriteItem, rhs: SpriteItem) -> Bool {
        return lhs.id == rhs.id
    }
}
