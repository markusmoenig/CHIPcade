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
    @Published var type: MemoryType

    private enum CodingKeys: String, CodingKey {
        case id, memory, name, startAddress, type
    }
    
    init(name: String, length: Int, type: MemoryType) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.memory = Array(repeating: .unsigned16Bit(0), count: length)  // Default to unsigned16Bit
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        memory = try container.decode([ChipCadeData].self, forKey: .memory)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(MemoryType.self, forKey: .type)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(memory, forKey: .memory)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
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
}

enum MemoryType: String, Codable {
    case code, sprite, data
}
