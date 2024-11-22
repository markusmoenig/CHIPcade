//
//  AudioItem.swift
//  CHIPcade
//
//  Created by Markus Moenig on 22/11/24.
//

import Combine
import SwiftUI

class AudioItem : ObservableObject, Codable, Equatable, Identifiable {
    var id: UUID

    var data: Data? = nil
    @Published var name: String

    private enum CodingKeys: String, CodingKey {
        case id, data, name
    }
    
    init(name: String, data: Data) {
        self.id = UUID()
        self.name = name
        self.data = data
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        data = try container.decode(Data?.self, forKey: .data)
        name = try container.decode(String.self, forKey: .name)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(data, forKey: .data)
        try container.encode(name, forKey: .name)
    }
    
    func rename(to newName: String, using undoManager: UndoManager?, setSelectedItem: @escaping (AudioItem?) -> Void) {
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
        undoManager?.setActionName("Rename Code Item")
    }
    
    static func == (lhs: AudioItem, rhs: AudioItem) -> Bool {
        return lhs.id == rhs.id
    }
}
