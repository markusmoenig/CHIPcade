//
//  MemoryItem.swift
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//

import Combine
import SwiftUI

class MemoryItem : ObservableObject, Codable, Equatable, Identifiable {
    var id: UUID

    @Published var memory: [ChipCadeData]
    @Published var name: String

    private enum CodingKeys: String, CodingKey {
        case id, memory, name, startAddress, type
    }
    
    init(name: String, length: Int) {
        self.id = UUID()
        self.name = name
        self.memory = Array(repeating: .unsigned16Bit(0), count: length)  // Default to unsigned16Bit
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        memory = try container.decode([ChipCadeData].self, forKey: .memory)
        name = try container.decode(String.self, forKey: .name)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(memory, forKey: .memory)
        try container.encode(name, forKey: .name)
    }
    
    func rename(to newName: String, using undoManager: UndoManager?, setSelectedItem: @escaping (MemoryItem?) -> Void) {
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
    // Grow the memory by a given amount
    func growMemory(by amount: Int) {
        memory.append(contentsOf: Array(repeating: .unsigned16Bit(0), count: amount))
    }

    // Read a value at a specific index
    func readValue(at index: Int) -> ChipCadeData {
        return memory[index]
    }

    // Write a value at a specific index
    func writeValue(at index: Int, value: ChipCadeData) {
        memory[index] = value
    }
    
    static func == (lhs: MemoryItem, rhs: MemoryItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    // An instruction at the given index is about to change
    func aboutToChange(using undoManager: UndoManager?, newValue: ChipCadeData, at index: Int, text: String = "Memory Changed") {
        let previousValue = memory[index]
        
        memory[index] = newValue
        
        undoManager?.registerUndo(withTarget: self) { targetSelf in
            targetSelf.aboutToChange(using: undoManager, newValue: previousValue, at: index, text: text)
        }
        
        undoManager?.setActionName(text)
    }
    
}
