//
//  CodeItem.swift
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//

import Combine
import SwiftUI

class CodeItem : ObservableObject, Codable, Equatable, Identifiable {
    var id: UUID

    @Published var codes: [Instruction]
    @Published var name: String
    @Published var currInstr: Int

    private enum CodingKeys: String, CodingKey {
        case id, codes, name, currInstr
    }
    
    init(name: String) {
        id = UUID()
        self.name = name
        codes = [Instruction(.ldi), Instruction(.nop)]
        currInstr = 0
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        codes = try container.decode([Instruction].self, forKey: .codes)
        name = try container.decode(String.self, forKey: .name)
        currInstr = try container.decode(Int.self, forKey: .currInstr)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(codes, forKey: .codes)
        try container.encode(name, forKey: .name)
        try container.encode(currInstr, forKey: .currInstr)
    }
    
    // Grow the memory by a given amount
    func growMemory(by amount: Int) {
        //codes.append(contentsOf: Array(repeating: .nop(nil), count: amount))
    }

    // Read a value at a specific index
    func readCode(at index: Int) -> Instruction {
        return codes[index]
    }

    // Write a value at a specific index
    func writeCode(at index: Int, value: Instruction) {
        codes[index] = value
    }
    
    static func == (lhs: CodeItem, rhs: CodeItem) -> Bool {
        return lhs.id == rhs.id
    }
}
