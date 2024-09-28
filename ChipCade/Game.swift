//
//  Game.swift
//  ChipCade
//
//  Created by Markus Moenig on 28/9/24.
//

import Combine
import SwiftUI

public class Game       : ObservableObject, Codable
{
    @Published var memory: [UInt8] // Use @Published to trigger UI updates

    private enum CodingKeys: String, CodingKey {
        case memory
    }
    
    init() {
        self.memory = Array(repeating: 0, count: 16 * 1024)
    }
    
    required public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        memory = try container.decode([UInt8].self, forKey: .memory)
    }

    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(memory, forKey: .memory)
    }
    
    func readByte(at address: Int) -> UInt8 {
        return memory[address]
    }

    func writeByte(at address: Int, value: UInt8) {
        memory[address] = value
    }
}
